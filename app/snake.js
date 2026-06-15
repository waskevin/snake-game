const board = document.getElementById("board");
const scoreEl = document.getElementById("score");
const bestEl = document.getElementById("best");
const speedEl = document.getElementById("speed");
const statusEl = document.getElementById("status");
const startBtn = document.getElementById("startBtn");
const pauseBtn = document.getElementById("pauseBtn");
const controlButtons = Array.from(document.querySelectorAll("[data-dir]"));
const ctx = board.getContext("2d");

const gridSize = 20;
const cellCount = 24;
const initialSpeed = 170;
const bestKey = "snake-game-best-score";

let snake = [];
let food = null;
let direction = { x: 1, y: 0 };
let nextDirection = { x: 1, y: 0 };
let score = 0;
let best = Number(localStorage.getItem(bestKey) || 0);
let tickMs = initialSpeed;
let loopId = null;
let running = false;
let paused = false;

bestEl.textContent = String(best);

function resizeCanvas() {
  const side = Math.min(board.clientWidth, 640);
  board.width = side;
  board.height = side;
  draw();
}

function randomCell() {
  return {
    x: Math.floor(Math.random() * cellCount),
    y: Math.floor(Math.random() * cellCount),
  };
}

function spawnFood() {
  let candidate = randomCell();
  while (snake.some((segment) => segment.x === candidate.x && segment.y === candidate.y)) {
    candidate = randomCell();
  }
  food = candidate;
}

function updateHud() {
  scoreEl.textContent = String(score);
  speedEl.textContent = `${(initialSpeed / tickMs).toFixed(1)}x`;
}

function setStatus(message) {
  statusEl.textContent = message;
}

function startGame() {
  snake = [
    { x: 7, y: 12 },
    { x: 6, y: 12 },
    { x: 5, y: 12 },
  ];
  direction = { x: 1, y: 0 };
  nextDirection = { x: 1, y: 0 };
  score = 0;
  tickMs = initialSpeed;
  paused = false;
  running = true;
  spawnFood();
  updateHud();
  setStatus("游戏开始，吃掉果实吧。");
  window.clearTimeout(loopId);
  loop();
}

function endGame() {
  running = false;
  window.clearTimeout(loopId);
  if (score > best) {
    best = score;
    localStorage.setItem(bestKey, String(best));
    bestEl.textContent = String(best);
  }
  setStatus(`游戏结束，本局得分 ${score}。点击“开始 / 重新开始”再来一局。`);
}

function pauseGame() {
  if (!running) {
    return;
  }
  paused = !paused;
  if (paused) {
    window.clearTimeout(loopId);
    setStatus("已暂停，再次点击暂停按钮继续。");
  } else {
    setStatus("继续游戏。");
    loop();
  }
}

function changeDirection(dir) {
  const map = {
    up: { x: 0, y: -1 },
    down: { x: 0, y: 1 },
    left: { x: -1, y: 0 },
    right: { x: 1, y: 0 },
  };
  const candidate = map[dir];
  if (!candidate) {
    return;
  }
  if (candidate.x === -direction.x && candidate.y === -direction.y) {
    return;
  }
  nextDirection = candidate;
}

function move() {
  direction = nextDirection;
  const head = {
    x: snake[0].x + direction.x,
    y: snake[0].y + direction.y,
  };

  const hitWall =
    head.x < 0 ||
    head.y < 0 ||
    head.x >= cellCount ||
    head.y >= cellCount;

  const hitSelf = snake.some((segment) => segment.x === head.x && segment.y === head.y);

  if (hitWall || hitSelf) {
    endGame();
    return;
  }

  snake.unshift(head);

  if (food && head.x === food.x && head.y === food.y) {
    score += 10;
    if ((score / 10) % 3 === 0) {
      tickMs = Math.max(80, tickMs - 14);
    }
    spawnFood();
    updateHud();
    setStatus("吃到了果实，继续冲分。");
  } else {
    snake.pop();
  }
}

function drawGrid(side) {
  ctx.save();
  ctx.strokeStyle = "rgba(23, 50, 42, 0.06)";
  ctx.lineWidth = 1;
  for (let i = 0; i <= cellCount; i += 1) {
    const pos = (side / cellCount) * i;
    ctx.beginPath();
    ctx.moveTo(pos, 0);
    ctx.lineTo(pos, side);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, pos);
    ctx.lineTo(side, pos);
    ctx.stroke();
  }
  ctx.restore();
}

function draw() {
  const side = board.width;
  const size = side / cellCount;

  ctx.clearRect(0, 0, side, side);
  drawGrid(side);

  if (food) {
    ctx.fillStyle = "#d65a31";
    ctx.beginPath();
    ctx.arc((food.x + 0.5) * size, (food.y + 0.5) * size, size * 0.35, 0, Math.PI * 2);
    ctx.fill();
  }

  snake.forEach((segment, index) => {
    ctx.fillStyle = index === 0 ? "#17322a" : "#2f7d32";
    const inset = index === 0 ? 2 : 3;
    ctx.fillRect(segment.x * size + inset, segment.y * size + inset, size - inset * 2, size - inset * 2);
  });
}

function loop() {
  if (!running || paused) {
    draw();
    return;
  }
  move();
  draw();
  if (running) {
    loopId = window.setTimeout(loop, tickMs);
  }
}

window.addEventListener("keydown", (event) => {
  const mapping = {
    ArrowUp: "up",
    ArrowDown: "down",
    ArrowLeft: "left",
    ArrowRight: "right",
  };
  const dir = mapping[event.key];
  if (!dir) {
    return;
  }
  event.preventDefault();
  changeDirection(dir);
});

window.addEventListener("resize", resizeCanvas);
startBtn.addEventListener("click", startGame);
pauseBtn.addEventListener("click", pauseGame);
controlButtons.forEach((button) => {
  button.addEventListener("click", () => changeDirection(button.dataset.dir));
});

resizeCanvas();
draw();
