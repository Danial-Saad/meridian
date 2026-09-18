const screenshotRoot = 'assets/';
const screenshots = {
  today: screenshotRoot + 'today.jpg',
  focus: screenshotRoot + 'focus.jpg',
  settings: screenshotRoot + 'settings.jpg',
  analytics: screenshotRoot + 'analytics.jpg',
  resources: screenshotRoot + 'resources.jpg',
  planner: screenshotRoot + 'planner.jpg'
};
const logoSource = document.querySelector('.hero-logo, .brand img')?.src || '';

document.body.innerHTML = `
<div class="redesign">
  <header class="site-header"><div class="inner wrap">
    <a class="brand" href="#top" aria-label="Meridian home"><span>Meridian</span></a>
    <nav aria-label="Main navigation">
      <a href="#features">Features</a><a href="#screens">Screens</a><a href="#contact">Contact</a>
      <a href="https://www.mediafire.com/file/iwmh4837xvgcsbd/Meridian.apk/file" class="btn small" target="_blank" rel="noopener noreferrer">Download</a>
    </nav>
  </div></header>
  <main id="top">
    <section class="hero-new">
      <div class="hero-drift" aria-hidden="true">
        <span class="drift-item" style="left:8%;font-size:1.1rem;animation-duration:18s;animation-delay:-7s;--drift-x:10px">Build the habit</span>
        <span class="drift-item" style="left:72%;font-size:1.25rem;animation-duration:22s;animation-delay:-13s;--drift-x:-12px">Stay in focus</span>
        <span class="drift-item" style="left:22%;font-size:1rem;animation-duration:25s;animation-delay:-18s;--drift-x:-8px">Plan your day</span>
        <span class="drift-item" style="left:88%;font-size:1.05rem;animation-duration:20s;animation-delay:-4s;--drift-x:8px">Track your progress</span>
        ${logoSource ? `<img class="drift-item drift-logo" src="${logoSource}" style="left:50%;animation-duration:27s;animation-delay:-20s;--drift-x:14px" alt="">` : ''}
      </div>
      <div class="wrap">
      <p class="eyebrow">A calmer way to get things done</p>
      <h1>Plan your day.<br><span>Build your momentum.</span></h1>
      <p class="lead">Meridian brings planning, focus sessions, habits, and progress insights together in one clear workspace.</p>
      <div class="hero-actions"><a class="btn" href="https://www.mediafire.com/file/iwmh4837xvgcsbd/Meridian.apk/file" target="_blank" rel="noopener noreferrer">Download Meridian</a><a class="btn-secondary" href="#screens">Explore the app</a></div>
    </div></section>

    <section class="section" id="features"><div class="wrap">
      <div class="section-head"><p class="eyebrow">Everything in one place</p><h2>Turn intention into a routine that lasts.</h2><p>Simple tools, a focused interface, and useful feedback help you make steady progress without the noise.</p></div>
      <div class="feature-grid">
        <article class="feature-card"><div class="feature-icon">01</div><h3>Plan with clarity</h3><p>Organize your day on a visual timeline and move tasks around as your priorities change.</p></article>
        <article class="feature-card"><div class="feature-icon">02</div><h3>Focus deeply</h3><p>Start a focused session, keep one task in view, and make your attention count.</p></article>
        <article class="feature-card"><div class="feature-icon">03</div><h3>See your progress</h3><p>Review focus time, completion rates, habits, and trends so you know what is working.</p></article>
      </div>
    </div></section>

    <section class="section section-tint" id="screens"><div class="wrap">
      <div class="section-head"><p class="eyebrow">See it in action</p><h2>Designed for your everyday rhythm.</h2><p>Every screen has one job: help you decide what matters next.</p></div>
      <div class="media-grid">
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.today}" alt="Meridian Today dashboard"></div><h3>Your day at a glance</h3><p>Know where your time is going before the day gets away from you.</p></article>
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.planner}" alt="Meridian Planner timeline"></div><h3>A flexible timeline</h3><p>Plan tasks by time and adjust your schedule without starting over.</p></article>
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.focus}" alt="Meridian Focus Mode"></div><h3>Focus mode</h3><p>One task, full attention, and a simple timer to keep you moving.</p></article>
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.analytics}" alt="Meridian analytics dashboard"></div><h3>Useful insights</h3><p>Understand your focus time and consistency with clear progress data.</p></article>
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.resources}" alt="Meridian resources screen"></div><h3>Keep resources close</h3><p>Save courses, documentation, and useful links in one place.</p></article>
        <article class="media-card"><div class="phone-frame"><img src="${screenshots.settings}" alt="Meridian settings screen"></div><h3>Make it yours</h3><p>Choose the language, theme, time format, and routines that fit you.</p></article>
        <article class="media-card video-card"><div class="phone-frame"><video controls autoplay muted loop playsinline preload="metadata"><source src="assets/meridian-demo.mp4" type="video/mp4">Your browser does not support the video element.</video></div><h3>A quick look at Meridian</h3><p>Watch the flow in motion and see how the pieces work together.</p></article>
      </div>
    </div></section>

    <section class="section"><div class="wrap"><div class="download-panel">
      <h2>Make your next day more intentional.</h2><p>Download Meridian and bring your plans, focus time, and progress into one calm workspace.</p>
      <a class="btn" href="https://www.mediafire.com/file/iwmh4837xvgcsbd/Meridian.apk/file" target="_blank" rel="noopener noreferrer">Get Meridian</a>
    </div></div></section>

    <section class="section section-tint" id="contact"><div class="wrap">
      <div class="section-head"><p class="eyebrow">Contact us</p><h2>We would love to hear from you.</h2><p>Questions, feedback, or ideas for Meridian? Reach out to either of us directly.</p></div>
      <div class="contact-grid">
        <article class="contact-card"><h3>Ghadi</h3><p>Get in touch with Ghadi</p><div class="contact-links"><a href="mailto:alhusenghadi800@gmail.com">✉ Email Ghadi</a><a href="https://www.instagram.com/ghadi_alhusen" target="_blank" rel="noopener noreferrer">◎ Instagram</a></div></article>
        <article class="contact-card"><h3>Danial</h3><p>Get in touch with Danial</p><div class="contact-links"><a href="mailto:saaddanial590@gmail.com">✉ Email Danial</a><a href="https://www.instagram.com/danial_saad_o" target="_blank" rel="noopener noreferrer">◎ Instagram</a></div></article>
      </div>
    </div></section>
  </main>
  <footer class="site-footer-new"><div class="wrap"><div class="footer-row"><strong>Meridian</strong><div><a href="#features">Features</a> · <a href="#screens">Screens</a> · <a href="#contact">Contact</a></div></div><p class="footer-meta">Built to help you plan with clarity, focus with intention, and keep moving forward.</p></div></footer>
</div>`;

const animatedItems = document.querySelectorAll(
  '.redesign .feature-card, .redesign .media-card, .redesign .contact-card, .redesign .download-panel'
);

if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries, currentObserver) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        currentObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  animatedItems.forEach((item) => observer.observe(item));
} else {
  animatedItems.forEach((item) => item.classList.add('is-visible'));
}
