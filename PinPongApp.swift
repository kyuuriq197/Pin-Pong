import SwiftUI
import SpriteKit

@main
struct PinPongApp: App {
    private var gameScene: SKScene {
        let scene = PongScene()
        scene.scaleMode = .resizeFill
        return scene
    }

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
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .background(Color.black)
            .statusBarHidden()
    }
}

final class PongScene: SKScene {
    private let player = SKShapeNode(rectOf: CGSize(width: 13, height: 92), cornerRadius: 6)
    private let cpu = SKShapeNode(rectOf: CGSize(width: 13, height: 92), cornerRadius: 6)
    private let ball = SKShapeNode(circleOfRadius: 9)
    private let playerScoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let cpuScoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "Menlo")
    private let centerLine = SKShapeNode()

    private var playerScore = 0
    private var cpuScore = 0
    private var ballVelocity = CGVector(dx: 330, dy: 170)
    private var previousTime: TimeInterval = 0
    private var isPlaying = false
    private var isGameOver = false
    private var lastPoint = CGPoint.zero

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.025, green: 0.035, blue: 0.055, alpha: 1)
        buildScene()
        resetBall(toward: 1)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        layoutScene()
    }

    private func buildScene() {
        [player, cpu, ball].forEach {
            $0.fillColor = SKColor(red: 0.35, green: 0.96, blue: 0.72, alpha: 1)
            $0.strokeColor = .clear
            addChild($0)
        }

        centerLine.strokeColor = SKColor(white: 1, alpha: 0.22)
        centerLine.lineWidth = 3
        centerLine.path = dashedLine(from: CGPoint(x: 0, y: -size.height), to: CGPoint(x: 0, y: size.height))
        addChild(centerLine)

        [playerScoreLabel, cpuScoreLabel].forEach {
            $0.fontSize = 42
            $0.fontColor = SKColor(white: 1, alpha: 0.88)
            $0.verticalAlignmentMode = .center
            addChild($0)
        }

        titleLabel.text = "PIN PONG"
        titleLabel.fontSize = 15
        titleLabel.fontColor = SKColor(red: 0.35, green: 0.96, blue: 0.72, alpha: 1)
        addChild(titleLabel)

        hintLabel.fontSize = 12
        hintLabel.fontColor = SKColor(white: 1, alpha: 0.58)
        addChild(hintLabel)

        layoutScene()
        updateScore()
        hintLabel.text = "TOUCH AND DRAG TO MOVE"
    }

    private func layoutScene() {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return }

        player.position = CGPoint(x: -w * 0.42, y: 0)
        cpu.position = CGPoint(x: w * 0.42, y: 0)
        playerScoreLabel.position = CGPoint(x: -w * 0.12, y: h * 0.31)
        cpuScoreLabel.position = CGPoint(x: w * 0.12, y: h * 0.31)
        titleLabel.position = CGPoint(x: 0, y: h * 0.39)
        hintLabel.position = CGPoint(x: 0, y: -h * 0.40)
        centerLine.path = dashedLine(from: CGPoint(x: 0, y: -h * 0.42), to: CGPoint(x: 0, y: h * 0.42))
        player.position.y = min(max(player.position.y, -h * 0.34), h * 0.34)
        cpu.position.y = min(max(cpu.position.y, -h * 0.34), h * 0.34)
    }

    private func dashedLine(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = CGMutablePath()
        let total = end.y - start.y
        let segment: CGFloat = 15
        var y = start.y
        while y < end.y {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: 0, y: min(y + segment, end.y)))
            y += segment * 2
        }
        _ = total
        return path
    }

    private func updateScore() {
        playerScoreLabel.text = "\(playerScore)"
        cpuScoreLabel.text = "\(cpuScore)"
    }

    private func resetBall(toward direction: CGFloat) {
        ball.position = .zero
        ballVelocity = CGVector(dx: 330 * direction, dy: CGFloat.random(in: -190...190))
        isPlaying = false
        hintLabel.text = isGameOver ? "TAP TO PLAY AGAIN" : "TAP TO SERVE"
    }

    private func serve() {
        guard !isGameOver else {
            playerScore = 0
            cpuScore = 0
            updateScore()
            isGameOver = false
            resetBall(toward: Bool.random() ? 1 : -1)
            return
        }
        isPlaying = true
        hintLabel.text = "FIRST TO 10 WINS"
    }

    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 { previousTime = currentTime }
        let dt = min(currentTime - previousTime, 1.0 / 30.0)
        previousTime = currentTime
        guard isPlaying, !isGameOver else { return }

        ball.position.x += ballVelocity.dx * dt
        ball.position.y += ballVelocity.dy * dt

        let limitY = size.height * 0.40
        if ball.position.y > limitY || ball.position.y < -limitY {
            ballVelocity.dy *= -1
            ball.position.y = min(max(ball.position.y, -limitY), limitY)
        }

        let cpuTarget = ball.position.y
        let cpuStep = 250 * dt
        if cpu.position.y < cpuTarget {
            cpu.position.y += min(cpuStep, cpuTarget - cpu.position.y)
        } else {
            cpu.position.y -= min(cpuStep, cpu.position.y - cpuTarget)
        }
        cpu.position.y = min(max(cpu.position.y, -size.height * 0.34), size.height * 0.34)

        checkPaddleCollision(paddle: player, movingRight: ballVelocity.dx < 0)
        checkPaddleCollision(paddle: cpu, movingRight: ballVelocity.dx > 0)

        if ball.position.x < -size.width * 0.52 {
            cpuScore += 1
            pointScored(toward: 1)
        } else if ball.position.x > size.width * 0.52 {
            playerScore += 1
            pointScored(toward: -1)
        }
    }

    private func checkPaddleCollision(paddle: SKShapeNode, movingRight: Bool) {
        let dx = ball.position.x - paddle.position.x
        let dy = abs(ball.position.y - paddle.position.y)
        let crossed = movingRight ? dx >= -12 && dx <= 12 : dx <= 12 && dx >= -12
        guard crossed, dy < 54 else { return }
        ballVelocity.dx *= -1.06
        let offset = (ball.position.y - paddle.position.y) / 46
        ballVelocity.dy = max(-430, min(430, ballVelocity.dy + offset * 150))
        ball.position.x = paddle.position.x + (movingRight ? 22 : -22)
    }

    private func pointScored(toward direction: CGFloat) {
        updateScore()
        if playerScore >= 10 || cpuScore >= 10 {
            isPlaying = false
            isGameOver = true
            hintLabel.text = playerScore >= 10 ? "YOU WIN — TAP TO RESTART" : "CPU WINS — TAP TO RESTART"
        } else {
            resetBall(toward: direction)
        }
    }

    private func movePlayer(to point: CGPoint) {
        let local = convertPoint(fromView: point)
        let limit = size.height * 0.34
        player.position.y = min(max(local.y, -limit), limit)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: view)
        movePlayer(to: lastPoint)
        if !isPlaying { serve() }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: view)
        movePlayer(to: lastPoint)
    }
}
