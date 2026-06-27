  function switchTab(platform) {
    document.querySelectorAll('.tab-btn').forEach((button) => {
      button.classList.toggle('active', button.textContent.toLowerCase().includes(platform === 'mac' ? 'macos' : 'windows'));
    });
    document.querySelectorAll('.tab-panel').forEach((panel) => panel.classList.remove('active'));
    document.getElementById('panel-' + platform).classList.add('active');
  }

  function copyOneliner(btn) {
    const code = btn.parentElement.querySelector('code').textContent;
    navigator.clipboard.writeText(code).then(() => {
      btn.textContent = '已复制';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = '复制';
        btn.classList.remove('copied');
      }, 1800);
    });
  }

  (function runSignalCompression() {
    const stage = document.getElementById('compressionStage');
    const scanline = document.getElementById('compressionScanline');
    const statusline = document.getElementById('terminalStatusline');
    if (!stage || !scanline || !statusline) return;

    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const fragments = Array.from(stage.querySelectorAll('.signal-fragment'));
    const statusParts = new Map(
      Array.from(statusline.querySelectorAll('[data-status-part]')).map((part) => [part.dataset.statusPart, part])
    );

    function statusTargetFor(fragment) {
      const key = fragment.dataset.target;
      if (key === 'add') return statusParts.get('add');
      return statusParts.get(key);
    }

    function compressFragment(fragment, index) {
      const target = statusTargetFor(fragment);
      if (!target) return;

      const from = fragment.getBoundingClientRect();
      const to = target.getBoundingClientRect();
      const dx = to.left + to.width / 2 - (from.left + from.width / 2);
      const dy = to.top + to.height / 2 - (from.top + from.height / 2);

      setTimeout(() => {
        fragment.classList.add('is-detected');
        target.classList.add('is-receiving');
      }, index * 80);

      setTimeout(() => {
        fragment.style.transform = `translate3d(${dx}px, ${dy}px, 0) scale(.72)`;
        fragment.style.filter = 'blur(1px) brightness(1.4)';
        fragment.classList.add('is-compressed');
      }, 120 + index * 80);

      setTimeout(() => target.classList.remove('is-receiving'), 760 + index * 80);
    }

    if (reduceMotion || window.innerWidth < 640) {
      stage.hidden = true;
      return;
    }

    fragments.forEach((fragment, index) => {
      setTimeout(() => fragment.classList.add('is-visible'), 520 + index * 90);
    });

    setTimeout(() => scanline.classList.add('is-scanning'), 1180);
    setTimeout(() => {
      scanline.classList.add('is-done');
      fragments.forEach(compressFragment);
    }, 1960);
    setTimeout(() => statusline.classList.add('is-locked'), 3100);
    setTimeout(() => {
      stage.hidden = true;
      statusline.classList.remove('is-locked');
    }, 4200);
  })();

  (function runTerminalSession() {
    const viewport = document.getElementById('terminalLogViewport');
    const el = document.getElementById('typing');
    const SLOT_COUNT = 6;
    const SLOT_HEIGHT = 31;

    const slots = [];
    for (let i = 0; i < SLOT_COUNT; i++) {
      const div = document.createElement('div');
      div.className = 'terminal-log-slot';
      div.style.top = (i * SLOT_HEIGHT) + 'px';
      viewport.appendChild(div);
      slots.push(div);
    }

    const lines = [
      '扫描 Git 分支与 dirty 状态...',
      '读取 context_window.used_percentage...',
      '统计本轮会话 diff...',
      '刷新状态栏输出...',
      '清理模型名后缀 [1m]...',
      '检测 NO_COLOR / CLAUDE_STATUSLINE_COLOR...',
      '输出紧凑状态行...'
    ];
    let lineIdx = 0;
    let charIdx = 0;
    let pause = 0;
    let slotCursor = 0;
    let linesWritten = 0;

    function addLogLine(text) {
      const slot = slots[slotCursor];
      if (linesWritten >= SLOT_COUNT) {
        slot.classList.remove('visible', 'entering');
        slot.classList.add('leaving');
      }
      const delay = linesWritten >= SLOT_COUNT ? 140 : 0;
      setTimeout(() => {
        slot.textContent = text;
        slot.classList.remove('leaving');
        void slot.offsetWidth;
        slot.classList.add('entering');
        setTimeout(() => {
          slot.classList.remove('entering');
          slot.classList.add('visible');
        }, 440);
      }, delay);
      linesWritten++;
      slotCursor = (slotCursor + 1) % SLOT_COUNT;
    }

    function tick() {
      if (pause > 0) {
        pause -= 1;
        setTimeout(tick, 50);
        return;
      }
      const line = lines[lineIdx];
      el.textContent = line.slice(0, charIdx);
      charIdx += 1;
      if (charIdx <= line.length) {
        setTimeout(tick, 22 + Math.random() * 28);
        return;
      }
      addLogLine(line);
      el.textContent = '';
      charIdx = 0;
      lineIdx = (lineIdx + 1) % lines.length;
      pause = 8;
      setTimeout(tick, 50);
    }

    setTimeout(tick, 500);
  })();

  (function runStatuslineLoop() {
    const statusline = document.getElementById('terminalStatusline');
    const branch = document.getElementById('statusBranch');
    const ctx = document.getElementById('statusCtx');
    const add = document.getElementById('statusAdd');
    const rm = document.getElementById('statusRm');

    // 当前显示的数值 (用于平滑计数)
    let curCtx = 4;
    let curAdd = 218;
    let curRm = 47;

    // 模拟真实终端逐步增长的会话数据
    const frames = [
      { ctx: 5,  add: 225, rm: 49 },
      { ctx: 7,  add: 237, rm: 51 },
      { ctx: 6,  add: 244, rm: 52 },
      { ctx: 9,  add: 256, rm: 55 },
      { ctx: 8,  add: 268, rm: 56 },
      { ctx: 11, add: 279, rm: 59 },
      { ctx: 10, add: 291, rm: 60 },
      { ctx: 13, add: 303, rm: 63 },
      { ctx: 12, add: 312, rm: 63 },
      { ctx: 14, add: 322, rm: 66 },
      { ctx: 15, add: 335, rm: 68 },
      { ctx: 17, add: 348, rm: 71 }
    ];
    let idx = 0;

    // 平滑计数：easeOutCubic
    function countTo(start, end, duration, onUpdate) {
      const startTime = performance.now();
      function tick(now) {
        const elapsed = now - startTime;
        const p = Math.min(elapsed / duration, 1);
        // easeOutCubic: 开始快，末尾减速
        const eased = 1 - Math.pow(1 - p, 3);
        const val = Math.round(start + (end - start) * eased);
        onUpdate(val);
        if (p < 1) requestAnimationFrame(tick);
      }
      requestAnimationFrame(tick);
    }

    function refresh() {
      idx = (idx + 1) % frames.length;
      const f = frames[idx];

      branch.textContent = '[feature/v1.1.0]*';

      statusline.classList.add('is-refreshing');

      // ctx 计数
      const nextCtx = f.ctx;
      countTo(curCtx, nextCtx, 240, (v) => { ctx.textContent = v + '%'; });
      curCtx = nextCtx;

      // add 计数
      const nextAdd = f.add;
      countTo(curAdd, nextAdd, 240, (v) => { add.textContent = '+' + v; });
      curAdd = nextAdd;

      // rm 计数
      const nextRm = f.rm;
      countTo(curRm, nextRm, 240, (v) => { rm.textContent = '-' + v; });
      curRm = nextRm;

      // 计数完成后取消高亮
      setTimeout(() => statusline.classList.remove('is-refreshing'), 260);
    }

    setInterval(refresh, 3200);
  })();
