import BezelKit
import SwiftUI
import UIKit

enum SheetDetent: Equatable {
  case fitContent

  func height(in containerHeight: CGFloat, contentHeight: CGFloat? = nil) -> CGFloat {
    contentHeight ?? containerHeight * 0.5
  }

  var isTall: Bool { false }
}

struct SheetDismissAction {
  fileprivate var handler: (_ completion: (() -> Void)?) -> Void = { $0?() }

  func callAsFunction() { handler(nil) }

  func callAsFunction(completion: @escaping () -> Void) {
    handler(completion)
  }
}

extension EnvironmentValues {
  @Entry var sheetDismiss = SheetDismissAction()
}

private final class ObservingHostingController: UIHostingController<AnyView> {
  var onLayoutChange: (() -> Void)?

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    onLayoutChange?()
  }
}

final class CustomSheetViewController: UIViewController, UIGestureRecognizerDelegate {
  var detents: [SheetDetent] = [.fitContent]
  var showsDragIndicator = false
  var isInteractiveDismissDisabled = false
  var onDismiss: (() -> Void)?
  var onFullyDismissed: (() -> Void)?

  private let initialContent: AnyView
  private var hostingController: ObservingHostingController?

  private let containerView = UIView()
  private let backdropView = UIView()
  private let dragIndicator = UIView()

  private var panGesture: UIPanGestureRecognizer!
  private var restingOrigin: CGFloat = 0
  private var currentDetentIndex = 0

  private var animator: UIViewPropertyAnimator?
  private(set) var isDismissing = false
  private var isAnimatingIn = false

  private var keyboardHeight: CGFloat = 0
  private let keyboardBottomPadding: CGFloat = 8

  private let sheetHorizontalPadding: CGFloat = 8
  private let sheetBottomPadding: CGFloat = 24
  private let maxUpwardDrag: CGFloat = 25

  private var sheetCornerRadius: CGFloat {
    let radius = CGFloat.deviceBezel(with: sheetHorizontalPadding)
    return radius > 0 ? radius : 38
  }

  private var usesInternalKeyboardAvoidance: Bool {
    detents.contains { $0.isTall }
  }

  init(content: AnyView) {
    self.initialContent = content
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupBackdrop()
    setupHostingController()
    setupContainer()
    setupContent()
    setupDragIndicator()
    setupGestures()
    setupKeyboardObservers()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    animateIn()
  }

  private func setupBackdrop() {
    backdropView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    backdropView.alpha = 0
    backdropView.frame = view.bounds
    backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(backdropView)

    let tap = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
    backdropView.addGestureRecognizer(tap)
  }

  private func setupContainer() {
    containerView.backgroundColor = UIColor(Theme.background)
    containerView.layer.cornerRadius = sheetCornerRadius
    containerView.layer.cornerCurve = .continuous
    containerView.clipsToBounds = true
    containerView.accessibilityViewIsModal = true
    containerView.frame = CGRect(
      x: sheetHorizontalPadding,
      y: view.bounds.height,
      width: view.bounds.width - sheetHorizontalPadding * 2,
      height: currentDetentHeight
    )
    view.addSubview(containerView)
  }

  private func setupDragIndicator() {
    guard showsDragIndicator else { return }
    dragIndicator.backgroundColor = UIColor(Theme.fg4).withAlphaComponent(0.12)
    dragIndicator.layer.cornerRadius = 2.5
    dragIndicator.frame = CGRect(x: 0, y: 8, width: 36, height: 5)
    containerView.addSubview(dragIndicator)
    dragIndicator.center.x = containerView.bounds.width / 2
    dragIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
  }

  private func setupHostingController() {
    let hosting = ObservingHostingController(rootView: initialContent)
    hosting.view.backgroundColor = .clear
    hosting.safeAreaRegions = usesInternalKeyboardAvoidance ? .keyboard : []
    hosting.onLayoutChange = { [weak self] in
      guard let self, !isAnimatingIn, !isDismissing else { return }
      resizeToFitContent()
    }
    hostingController = hosting
  }

  private func setupContent() {
    guard let hosting = hostingController else { return }
    addChild(hosting)
    containerView.addSubview(hosting.view)
    hosting.didMove(toParent: self)
    hosting.view.translatesAutoresizingMaskIntoConstraints = true
    hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hosting.view.frame = containerView.bounds
  }

  private func setupGestures() {
    panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    panGesture.delegate = self
    containerView.addGestureRecognizer(panGesture)
  }

  func updateContent(_ newContent: AnyView) {
    hostingController?.rootView = newContent
    guard view.window != nil, !isAnimatingIn else { return }
    resizeToFitContent()
    Task { @MainActor [weak self] in
      self?.resizeToFitContent()
    }
  }

  private func resizeToFitContent() {
    guard detents.contains(.fitContent) else { return }
    let newHeight = currentDetentHeight
    guard abs(containerView.frame.height - newHeight) > 1 else { return }

    animator?.stopAnimation(true)
    animator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: UISpringTimingParameters(damping: 0.85, response: 0.225)
    )
    animator?.addAnimations {
      self.containerView.frame.origin.y = self.restingY(for: newHeight)
      self.containerView.frame.size.height = newHeight
    }
    animator?.startAnimation()
  }

  private var intrinsicContentHeight: CGFloat {
    guard let hosting = hostingController else { return 0 }
    let targetWidth = view.bounds.width - sheetHorizontalPadding * 2
    return hosting.sizeThatFits(
      in: CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
    ).height
  }

  private var currentDetentHeight: CGFloat {
    guard !detents.isEmpty else { return view.bounds.height * 0.5 }
    let index = min(currentDetentIndex, detents.count - 1)
    return detents[index].height(in: view.bounds.height, contentHeight: intrinsicContentHeight)
  }

  private var sortedDetentHeights: [CGFloat] {
    let contentHeight = intrinsicContentHeight
    return
      detents
      .map { $0.height(in: view.bounds.height, contentHeight: contentHeight) }
      .sorted()
  }

  private func restingY(for height: CGFloat) -> CGFloat {
    let keyboardOffset =
      keyboardHeight > 0 && !usesInternalKeyboardAvoidance
      ? keyboardHeight + keyboardBottomPadding - sheetBottomPadding
      : 0
    return view.bounds.height - height - sheetBottomPadding - keyboardOffset
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillChange(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  @objc private func keyboardWillChange(_ notification: Notification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    else { return }
    keyboardHeight = frame.height
    animateAlongsideKeyboard(notification)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    keyboardHeight = 0
    animateAlongsideKeyboard(notification)
  }

  private func animateAlongsideKeyboard(_ notification: Notification) {
    guard
      !isDismissing, !usesInternalKeyboardAvoidance,
      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        as? TimeInterval,
      let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
    else { return }

    let targetY = restingY(for: containerView.frame.height)
    UIView.animate(
      withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curveRaw << 16)
    ) {
      self.containerView.frame.origin.y = targetY
    }
  }

  private func animateIn() {
    isAnimatingIn = true
    let sheetHeight = currentDetentHeight
    containerView.frame.size.height = sheetHeight
    if UIAccessibility.isReduceMotionEnabled {
      containerView.frame.origin.y = restingY(for: sheetHeight)
      backdropView.alpha = 1
      isAnimatingIn = false
      return
    }

    animator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: UISpringTimingParameters(damping: 0.8, response: 0.36)
    )
    animator?.addAnimations {
      self.backdropView.alpha = 1
      self.containerView.frame.origin.y = self.restingY(for: sheetHeight)
    }
    animator?.addCompletion { _ in
      self.isAnimatingIn = false
    }
    animator?.startAnimation()
  }

  func animateOut(completion: (() -> Void)? = nil) {
    guard !isDismissing else {
      completion?()
      return
    }
    isDismissing = true
    view.endEditing(true)

    Task { @MainActor [weak self] in
      self?.onDismiss?()
    }

    if UIAccessibility.isReduceMotionEnabled {
      dismiss(animated: false) {
        completion?()
        self.onFullyDismissed?()
        self.onFullyDismissed = nil
      }
      return
    }

    animator?.stopAnimation(true)
    animator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: UISpringTimingParameters(damping: 1.0, response: 0.3)
    )
    animator?.addAnimations {
      self.backdropView.alpha = 0
      self.containerView.frame.origin.y = self.view.bounds.height
    }
    animator?.addCompletion { _ in
      self.dismiss(animated: false) {
        completion?()
        self.onFullyDismissed?()
        self.onFullyDismissed = nil
      }
    }
    animator?.startAnimation()
  }

  private func animateToDetent(at index: Int, velocity: CGFloat = 0) {
    currentDetentIndex = index
    let targetHeight = sortedDetentHeights[index]
    let targetY = restingY(for: targetHeight)

    let distance = targetY - containerView.frame.origin.y
    let initialVelocity = distance != 0 ? velocity / distance : 0

    animator?.stopAnimation(true)
    animator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: UISpringTimingParameters(
        damping: 0.85,
        response: 0.4,
        initialVelocity: CGVector(dx: 0, dy: initialVelocity)
      )
    )
    animator?.addAnimations {
      self.containerView.frame.origin.y = targetY
      self.containerView.frame.size.height = targetHeight
      self.updateBackdropAlpha(for: targetY)
    }
    animator?.startAnimation()
  }

  private func updateBackdropAlpha(for sheetY: CGFloat) {
    let maxY = view.bounds.height
    let minY = maxY - (sortedDetentHeights.last ?? maxY) - sheetBottomPadding
    let progress = 1 - (sheetY - minY) / (maxY - minY)
    backdropView.alpha = max(0, min(1, progress))
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: view)
    let velocity = gesture.velocity(in: view)

    let sheetHeight = sortedDetentHeights.first ?? 0
    let restingY = restingY(for: sheetHeight)
    let absoluteMinY = restingY - maxUpwardDrag

    switch gesture.state {
    case .began:
      animator?.stopAnimation(true)
      let currentY =
        containerView.layer.presentation()?.frame.origin.y ?? containerView.frame.origin.y
      containerView.frame.origin.y = currentY
      restingOrigin = restingY

    case .changed:
      let rawY = restingOrigin + translation.y
      var newY: CGFloat
      if rawY < restingY {
        let overscroll = restingY - rawY
        newY = restingY - rubberBand(overscroll, dimension: 120) * 0.25
        newY = max(newY, absoluteMinY)
      } else {
        newY = rawY
      }
      containerView.frame.origin.y = newY
      updateBackdropAlpha(for: newY)

    case .ended, .cancelled:
      let currentY = containerView.frame.origin.y
      let projectedY = velocity.y > 0 ? currentY + project(velocity: velocity.y) : currentY
      let dragDistance = currentY - restingY
      let percentDragged = sheetHeight > 0 ? dragDistance / sheetHeight : 0
      let shouldDismiss =
        percentDragged > 0.5 || velocity.y > 800 || projectedY > restingY + sheetHeight * 0.5

      if shouldDismiss, velocity.y >= 0, !isInteractiveDismissDisabled {
        animateOut()
      } else {
        animateToDetent(at: nearestDetentIndex(for: currentY), velocity: max(velocity.y, 0))
      }

    default:
      break
    }
  }

  override func accessibilityPerformEscape() -> Bool {
    guard !isInteractiveDismissDisabled else { return false }
    animateOut()
    return true
  }

  @objc private func backdropTapped() {
    guard !isInteractiveDismissDisabled else { return }
    animateOut()
  }

  private func rubberBand(_ offset: CGFloat, dimension: CGFloat) -> CGFloat {
    let constant: CGFloat = 0.55
    let result = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    return offset < 0 ? -result : result
  }

  private func project(velocity: CGFloat, decelerationRate: CGFloat = 0.998) -> CGFloat {
    velocity * decelerationRate / (1 - decelerationRate) * 0.001
  }

  private func nearestDetentIndex(for y: CGFloat) -> Int {
    var nearestIndex = 0
    var nearestDistance = CGFloat.infinity
    for (index, height) in sortedDetentHeights.enumerated() {
      let distance = abs(y - restingY(for: height))
      if distance < nearestDistance {
        nearestDistance = distance
        nearestIndex = index
      }
    }
    return nearestIndex
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
  ) -> Bool {
    false
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: containerView)
    return abs(velocity.y) > abs(velocity.x) && abs(velocity.y) > 50
  }
}

extension UISpringTimingParameters {
  convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
    let stiffness = pow(2 * .pi / response, 2)
    let dampingCoefficient = 4 * .pi * damping / response
    self.init(
      mass: 1, stiffness: stiffness, damping: dampingCoefficient, initialVelocity: initialVelocity)
  }
}

private struct SheetRoot<Content: View>: View {
  let content: Content
  let dismiss: SheetDismissAction

  var body: some View {
    content.environment(\.sheetDismiss, dismiss)
  }
}

private final class SheetAnchorViewController: UIViewController {
  var onReady: (() -> Void)?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    onReady?()
    onReady = nil
  }
}

private struct CustomSheetPresenter<SheetContent: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let detents: [SheetDetent]
  let showsDragIndicator: Bool
  let isInteractiveDismissDisabled: Bool
  let content: () -> SheetContent

  func makeUIViewController(context: Context) -> SheetAnchorViewController {
    SheetAnchorViewController()
  }

  static func dismantleUIViewController(
    _ uiViewController: SheetAnchorViewController, coordinator: ()
  ) {
    if let presented = uiViewController.presentedViewController {
      presented.dismiss(animated: false)
    }
  }

  func updateUIViewController(_ uiViewController: SheetAnchorViewController, context: Context) {
    if isPresented {
      if let presented = uiViewController.presentedViewController as? CustomSheetViewController {
        if presented.isDismissing {
          presented.onFullyDismissed = { [weak uiViewController] in
            guard let uiViewController else { return }
            Task { @MainActor in
              guard isPresented, uiViewController.presentedViewController == nil else { return }
              present(from: uiViewController)
            }
          }
        } else {
          presented.isInteractiveDismissDisabled = isInteractiveDismissDisabled
          presented.updateContent(
            AnyView(
              SheetRoot(
                content: content(),
                dismiss: SheetDismissAction { [weak presented] completion in
                  presented?.animateOut(completion: completion)
                }
              )
            )
          )
        }
      } else if uiViewController.presentedViewController == nil {
        if uiViewController.view.window != nil {
          present(from: uiViewController)
        } else {
          uiViewController.onReady = { [weak uiViewController] in
            guard let uiViewController, isPresented, uiViewController.presentedViewController == nil
            else { return }
            present(from: uiViewController)
          }
        }
      }
    } else {
      uiViewController.onReady = nil
      if let presented = uiViewController.presentedViewController as? CustomSheetViewController {
        presented.onFullyDismissed = nil
        Task { @MainActor in
          presented.animateOut()
        }
      }
    }
  }

  private func present(from presenter: UIViewController) {
    var animateOut: ((() -> Void)?) -> Void = { $0?() }
    let sheetVC = CustomSheetViewController(
      content: AnyView(
        SheetRoot(
          content: content(),
          dismiss: SheetDismissAction { completion in
            animateOut(completion)
          }
        )
      )
    )
    sheetVC.detents = detents
    sheetVC.showsDragIndicator = showsDragIndicator
    sheetVC.isInteractiveDismissDisabled = isInteractiveDismissDisabled
    sheetVC.onDismiss = {
      isPresented = false
    }
    animateOut = { [weak sheetVC] completion in
      sheetVC?.animateOut(completion: completion)
    }
    presenter.present(sheetVC, animated: false)
  }
}

extension View {
  func customSheet<Content: View>(
    isPresented: Binding<Bool>,
    detents: [SheetDetent] = [.fitContent],
    showsDragIndicator: Bool = false,
    isInteractiveDismissDisabled: Bool = false,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    background(
      CustomSheetPresenter(
        isPresented: isPresented,
        detents: detents,
        showsDragIndicator: showsDragIndicator,
        isInteractiveDismissDisabled: isInteractiveDismissDisabled,
        content: content
      )
    )
  }
}
