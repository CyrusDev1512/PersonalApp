{{flutter_js}}
{{flutter_build_config}}

// Bản dùng thử (lib/main_demo.dart) đăng như trang tĩnh: CanvasKit và font nằm cạnh index.html,
// không có service worker, không tải gì từ Internet.
(function () {
  var loader = document.getElementById('demo-loader');
  var started = false;
  var failed = false;

  function say(message, note, isError) {
    if (!loader || started) return;
    if (isError) {
      failed = true;
      loader.classList.add('demo-failed');
      loader.setAttribute('role', 'alert');
    } else if (failed) {
      return; // đã báo lỗi thì không ghi đè bằng thông báo "đang tải"
    }
    var msg = loader.querySelector('.demo-message');
    var extra = loader.querySelector('.demo-note');
    if (msg) msg.textContent = message;
    if (extra) extra.textContent = note || '';
  }

  // CanvasKit là WebAssembly: trang chủ hoặc trình duyệt chặn WebAssembly thì app không thể vẽ được gì.
  // Hiện lời giải thích thay vì để trang trắng.
  function wasmBlocked() {
    say(
      'Không chạy được bản dùng thử ở đây: trình duyệt hoặc trang đang chặn WebAssembly.',
      'Hãy mở bằng Chrome, Edge, Firefox hoặc Safari bản mới, hoặc chạy bản web trên máy (xem README).',
      true
    );
  }
  function looksLikeWasm(reason) {
    return /WebAssembly|wasm|CompileError/i.test(String(reason && (reason.stack || reason.message) || reason));
  }
  document.addEventListener('securitypolicyviolation', function (e) {
    if (/wasm/i.test(e.blockedURI || '') || /wasm/i.test(e.violatedDirective || '')) wasmBlocked();
  });
  window.addEventListener('unhandledrejection', function (e) {
    if (looksLikeWasm(e.reason)) wasmBlocked();
  });
  window.addEventListener('error', function (e) {
    if (looksLikeWasm(e.error || e.message)) wasmBlocked();
  });
  if (typeof WebAssembly !== 'object') wasmBlocked();

  window.addEventListener('flutter-first-frame', function () {
    started = true;
    if (loader) loader.remove();
  }, { once: true });

  // Mạng chậm: sau 25 giây vẫn chưa thấy app thì nói rõ là vẫn đang tải.
  setTimeout(function () {
    say(
      'Vẫn đang tải bản dùng thử…',
      'Mạng chậm có thể mất 20–30 giây. Nếu trang vẫn trống sau một lúc, hãy tải lại trang.',
      false
    );
  }, 25000);

  _flutter.loader.load({
    config: {
      renderer: 'canvaskit',
      canvasKitBaseUrl: 'canvaskit/',
      // Nếu engine còn thiếu glyph thì cũng chỉ tìm font dự phòng cạnh trang, không gọi fonts.gstatic.com.
      fontFallbackBaseUrl: 'fonts/fallback/',
    },
  }).catch(function (e) {
    if (looksLikeWasm(e)) {
      wasmBlocked();
    } else {
      say('Không tải được bản dùng thử.', String(e), true);
    }
  });
})();
