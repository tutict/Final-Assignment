/**
 * 本地画布验证码弹窗，对齐 Flutter LocalCaptchaMain。
 *
 * 对齐点：
 * - 4 位字符，字符集 [a-zA-Z0-9]，大小写不敏感，10 分钟过期。
 * - 在 <canvas> 上随机绘制字符 + 干扰线/噪点，answer 存于 ref。
 * - 提供刷新按钮重新生成；验证失败刷新并清空，验证成功 onClose(true)。
 * - 仅用于注册与密码重置流程（普通登录不使用）。
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import Modal from './Modal';

interface LocalCaptchaProps {
  isOpen: boolean;
  onClose: (success: boolean) => void;
}

const CHARS = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890';
const LENGTH = 4;
const WIDTH = 320;
const HEIGHT = 140;

function randomCode(): string {
  let code = '';
  for (let i = 0; i < LENGTH; i += 1) {
    code += CHARS[Math.floor(Math.random() * CHARS.length)];
  }
  return code;
}

function drawCaptcha(canvas: HTMLCanvasElement, code: string): void {
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  ctx.clearRect(0, 0, WIDTH, HEIGHT);

  // 背景
  ctx.fillStyle = '#f1ede6';
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  // 干扰线
  for (let i = 0; i < 5; i += 1) {
    ctx.strokeStyle = `rgba(${Math.floor(Math.random() * 120)},${Math.floor(
      Math.random() * 120
    )},${Math.floor(Math.random() * 120)},0.4)`;
    ctx.beginPath();
    ctx.moveTo(Math.random() * WIDTH, Math.random() * HEIGHT);
    ctx.lineTo(Math.random() * WIDTH, Math.random() * HEIGHT);
    ctx.stroke();
  }

  // 字符
  const palette = ['#0c7c79', '#e67e22', '#2e8b57', '#c0392b', '#2f80ed'];
  for (let i = 0; i < code.length; i += 1) {
    ctx.save();
    const x = (WIDTH / LENGTH) * i + WIDTH / LENGTH / 2;
    const y = HEIGHT / 2 + (Math.random() * 20 - 10);
    ctx.translate(x, y);
    ctx.rotate((Math.random() * 60 - 30) * (Math.PI / 180));
    ctx.font = `${36 + Math.floor(Math.random() * 12)}px 'IBM Plex Sans', sans-serif`;
    ctx.fillStyle = palette[Math.floor(Math.random() * palette.length)];
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(code[i], 0, 0);
    ctx.restore();
  }

  // 噪点
  for (let i = 0; i < 60; i += 1) {
    ctx.fillStyle = `rgba(0,0,0,${Math.random() * 0.15})`;
    ctx.fillRect(Math.random() * WIDTH, Math.random() * HEIGHT, 1.5, 1.5);
  }
}

export default function LocalCaptcha({ isOpen, onClose }: LocalCaptchaProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const answerRef = useRef<string>('');
  const expireRef = useRef<number>(0);
  const [input, setInput] = useState('');
  const [error, setError] = useState('');

  const refresh = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const code = randomCode();
    answerRef.current = code;
    // 10 分钟过期
    expireRef.current = Date.now() + 10 * 60 * 1000;
    drawCaptcha(canvas, code);
    setInput('');
    setError('');
  }, []);

  useEffect(() => {
    if (isOpen) {
      refresh();
    }
  }, [isOpen, refresh]);

  const handleVerify = () => {
    const expected = answerRef.current.toLowerCase();
    if (!input) {
      setError('请输入验证码');
      return;
    }
    if (Date.now() > expireRef.current) {
      setError('验证码已过期，请刷新');
      refresh();
      return;
    }
    if (input.toLowerCase() === expected) {
      onClose(true);
    } else {
      setError('验证码错误，请重试');
      refresh();
    }
  };

  const handleCancel = () => {
    onClose(false);
  };

  return (
    <Modal
      isOpen={isOpen}
      title="请输入验证码"
      onClose={handleCancel}
      footerActions={
        <div className="modal-actions">
          <button type="button" className="ghost" onClick={handleCancel}>
            取消
          </button>
          <button type="button" className="primary" onClick={handleVerify}>
            验证
          </button>
        </div>
      }
    >
      <div className="captcha-wrap">
        <div className="captcha-canvas-row">
          <canvas
            ref={canvasRef}
            width={WIDTH}
            height={HEIGHT}
            className="captcha-canvas"
            aria-label="验证码图片"
          />
          <button type="button" className="ghost captcha-refresh" onClick={refresh}>
            刷新
          </button>
        </div>
        <input
          type="text"
          value={input}
          maxLength={LENGTH}
          placeholder={`输入 ${LENGTH} 位验证码`}
          className="captcha-input"
          onChange={(event) => {
            setInput(event.target.value);
            if (error) setError('');
          }}
          onKeyDown={(event) => {
            if (event.key === 'Enter') handleVerify();
          }}
        />
        {error ? <div className="form-error captcha-error">{error}</div> : null}
      </div>
    </Modal>
  );
}
