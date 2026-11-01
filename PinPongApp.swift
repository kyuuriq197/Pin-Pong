import SwiftUI
import SpriteKit

@main
struct PinPongApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}

struct GameView: View {
    private let scene: PongScene = {
        let scene = PongScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        GeometryReader { _ in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .background(Color.black)
                .statusBarHidden()
        }
        .background(Color.black)
    }
}

final class PongScene: SKScene {
    private let player = SKShapeNode()
    private let cpu = SKShapeNode()
    private let ball = SKShapeNode()
    private let playerScoreLabel = SKLabelNode(fontNamed: "Menlo")
    private let cpuScoreLabel = SKLabelNode(fontNamed: "Menlo")
    private let hintLabel = SKLabelNode(fontNamed: "Menlo")
    private let centerLine = SKShapeNode()

    private var playerScore = 0
    private var cpuScore = 0
    private var ballVelocity = CGVector.zero
    private var previousTime: TimeInterval = 0
    private var isPlaying = false
    private var isGameOver = false

    private var paddleSize = CGSize(width: 10, height: 70)
    private var ballRadius: CGFloat = 5
    private var paddleInset: CGFloat = 0
    private var playLimitY: CGFloat = 0
    private var baseBallSpeed: CGFloat = 360

    private let winningScore = 10
    private let white = SKColor.white

    override func didMove(to view: SKView) {
        backgroundColor = .black
        configureNodes()
        layoutGame()
        updateScore()
        resetBall(toward: Bool.random() ? 1 : -1)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        layoutGame()
    }

    private func configureNodes() {
        [player, cpu, ball].forEach {
            $0.fillColor = white
            $0.strokeColor = .clear
            addChild($0)
        }

        centerLine.strokeColor = SKColor(white: 1, alpha: 0.72)
        centerLine.lineWidth = 2
        addChild(centerLine)

        [playerScoreLabel, cpuScoreLabel].forEach {
            $0.fontColor = white
            $0.fontSize = 38
            $0.verticalAlignmentMode = .center
            $0.horizontalAlignmentMode = .center
            addChild($0)
        }

        hintLabel.fontColor = SKColor(white: 1, alpha: 0.65)
        hintLabel.fontSize = 11
        hintLabel.horizontalAlignmentMode = .center
        hintLabel.verticalAlignmentMode = .center
        addChild(hintLabel)
    }

    // All dimensions are recalculated from the current scene size.
    // This runs again after device rotation and on different iPhone screens.
    private func layoutGame() {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return }

        let shortSide = min(w, h)
        paddleSize = CGSize(
            width: max(9, shortSide * 0.025),
            height: min(h * 0.18, max(62, w * 0.18))
        )
        ballRadius = max(4, shortSide * 0.012)
        paddleInset = w * 0.085
        playLimitY = h * 0.43
        baseBallSpeed = shortSide * 1.05

        player.path = CGPath(
            rect: CGRect(x: -paddleSize.width / 2,
                         y: -paddleSize.height / 2,
                         width: paddleSize.width,
                         height: paddleSize.height),
            transform: nil
        )
        cpu.path = player.path

        let ballRect = CGRect(x: -ballRadius, y: -ballRadius,
                              width: ballRadius * 2, height: ballRadius * 2)
        ball.path = CGPath(ellipseIn: ballRect, transform: nil)

        player.position.x = -w / 2 + paddleInset
        cpu.position.x = w / 2 - paddleInset

        let paddleLimit = max(0, playLimitY - paddleSize.height / 2)
        player.position.y = min(max(player.position.y, -paddleLimit), paddleLimit)
        cpu.position.y = min(max(cpu.position.y, -paddleLimit), paddleLimit)

        let scoreY = h * 0.31
        playerScoreLabel.position = CGPoint(x: -w * 0.12, y: scoreY)
        cpuScoreLabel.position = CGPoint(x: w * 0.12, y: scoreY)
        let scoreFont = max(25, min(48, shortSide * 0.105))
        playerScoreLabel.fontSize = scoreFont
        cpuScoreLabel.fontSize = scoreFont

        hintLabel.position = CGPoint(x: 0, y: -h * 0.39)
        hintLabel.fontSize = max(9, min(13, shortSide * 0.03))

        let path = CGMutablePath()
        let dash: CGFloat = max(10, shortSide * 0.04)
        let gap = dash
        var y = -playLimitY
        while y < playLimitY {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: 0, y: min(y + dash, playLimitY)))
            y += dash + gap
        }
        centerLine.path = path

        if ball.parent != nil {
            ball.position.x = min(max(ball.position.x, -w * 0.35), w * 0.35)
            ball.position.y = min(max(ball.position.y, -playLimitY), playLimitY)
        }
    }

    private func updateScore() {
        playerScoreLabel.text = "\(playerScore)"
        cpuScoreLabel.text = "\(cpuScore)"
    }

    private func resetBall(toward direction: CGFloat) {
        ball.position = .zero
        let speed = baseBallSpeed
        ballVelocity = CGVector(
            dx: speed * direction,
            dy: CGFloat.random(in: -0.42...0.42) * speed
        )
        isPlaying = false
        hintLabel.text = isGameOver ? "TAP TO PLAY AGAIN" : "TAP TO SERVE"
    }

    private func serve() {
        if isGameOver {
            playerScore = 0
            cpuScore = 0
            isGameOver = false
            updateScore()
            resetBall(toward: Bool.random() ? 1 : -1)
        }
        isPlaying = true
        hintLabel.text = "FIRST TO 10"
    }

    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 {
            previousTime = currentTime
        }
        let dt = min(currentTime - previousTime, 1.0 / 30.0)
        previousTime = currentTime

        guard isPlaying, !isGameOver, dt > 0 else { return }

        let oldBallX = ball.position.x
        ball.position.x += ballVelocity.dx * dt
        ball.position.y += ballVelocity.dy * dt

        // Top and bottom walls.
        if ball.position.y + ballRadius >= playLimitY {
            ball.position.y = playLimitY - ballRadius
            ballVelocity.dy = -abs(ballVelocity.dy)
        } else if ball.position.y - ballRadius <= -playLimitY {
            ball.position.y = -playLimitY + ballRadius
            ballVelocity.dy = abs(ballVelocity.dy)
        }

        // CPU movement scales with the device instead of using a fixed point speed.
        let cpuTarget = ball.position.y
        let cpuStep = baseBallSpeed * 0.82 * dt
        if cpu.position.y < cpuTarget {
            cpu.position.y += min(cpuStep, cpuTarget - cpu.position.y)
        } else {
            cpu.position.y -= min(cpuStep, cpu.position.y - cpuTarget)
        }
        let paddleLimit = max(0, playLimitY - paddleSize.height / 2)
        cpu.position.y = min(max(cpu.position.y, -paddleLimit), paddleLimit)

        checkPaddleCollision(player, isLeft: true, oldBallX: oldBallX)
        checkPaddleCollision(cpu, isLeft: false, oldBallX: oldBallX)

        if ball.position.x < -size.width / 2 - ballRadius {
            cpuScore += 1
            pointScored(toward: 1)
        } else if ball.position.x > size.width / 2 + ballRadius {
            playerScore += 1
            pointScored(toward: -1)
        }
    }

    private func checkPaddleCollision(_ paddle: SKShapeNode,
                                      isLeft: Bool,
                                      oldBallX: CGFloat) {
        let directionIsCorrect = isLeft ? ballVelocity.dx < 0 : ballVelocity.dx > 0
        guard directionIsCorrect else { return }

        let faceX = paddle.position.x + (isLeft
            ? paddleSize.width / 2 + ballRadius
            : -paddleSize.width / 2 - ballRadius)

        let crossedFace = isLeft
            ? oldBallX > faceX && ball.position.x <= faceX
            : oldBallX < faceX && ball.position.x >= faceX

        let overlapsFace = abs(ball.position.x - faceX) <= abs(ballVelocity.dx) / 30 + 2
        let verticalDistance = abs(ball.position.y - paddle.position.y)
        guard (crossedFace || overlapsFace),
              verticalDistance <= paddleSize.height / 2 + ballRadius else { return }

        let hitOffset = (ball.position.y - paddle.position.y) / (paddleSize.height / 2)
        let newSpeed = min(baseBallSpeed * 1.65, hypot(ballVelocity.dx, ballVelocity.dy) * 1.035)
        let horizontalDirection: CGFloat = isLeft ? 1 : -1

        ballVelocity.dx = horizontalDirection * newSpeed * 0.88
        ballVelocity.dy = max(-newSpeed * 0.72,
                              min(newSpeed * 0.72, hitOffset * newSpeed * 0.72))
        ball.position.x = faceX + (isLeft ? 1 : -1)
    }

    private func pointScored(toward direction: CGFloat) {
        updateScore()
        if playerScore >= winningScore || cpuScore >= winningScore {
            isPlaying = false
            isGameOver = true
            hintLabel.text = playerScore >= winningScore
                ? "YOU WIN — TAP TO RESTART"
                : "CPU WINS — TAP TO RESTART"
        } else {
            resetBall(toward: direction)
        }
    }

    private func movePlayer(to point: CGPoint) {
        let limit = max(0, playLimitY - paddleSize.height / 2)
        player.position.y = min(max(point.y, -limit), limit)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        movePlayer(to: touch.location(in: self))
        if !isPlaying {
            serve()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        movePlayer(to: touch.location(in: self))
    }
}
