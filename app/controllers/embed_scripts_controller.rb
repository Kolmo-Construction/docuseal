# frozen_string_literal: true

# OSS-friendly embed widget. Renders a minimal iframe wrapper for the
# <docuseal-form data-src="..."> web component so OSS deployments can embed
# the signing form in any parent origin (assuming FRAME_ANCESTORS is set on
# the DocuSeal side to allow the parent).
#
# The Pro widget is richer (event bus, inline field nav, in-place builder),
# but for the common signer-embed case an iframe pointing at /s/<slug> is
# enough — and matches the same `data-src` attribute pattern Pro uses, so
# parent apps don't need to be aware of which edition is running.
class EmbedScriptsController < ActionController::Metal
  EMBED_SCRIPT = <<~JAVASCRIPT.freeze
    (function () {
      function iframeForElement(el) {
        var src = el.getAttribute('data-src');
        if (!src) return null;
        var iframe = document.createElement('iframe');
        iframe.src = src;
        iframe.title = el.getAttribute('data-title') || 'Sign document';
        iframe.allow = 'clipboard-read; clipboard-write';
        iframe.style.width = '100%';
        iframe.style.height = el.getAttribute('data-height') || '85vh';
        iframe.style.minHeight = '720px';
        iframe.style.border = '0';
        iframe.style.display = 'block';
        return iframe;
      }

      function mount(el) {
        // Idempotent: don't double-mount when the custom element is
        // re-attached (e.g. React StrictMode dev mode).
        if (el.querySelector('iframe')) return;
        var iframe = iframeForElement(el);
        if (!iframe) return;
        el.appendChild(iframe);
        // Tell the parent the embed has loaded.
        iframe.addEventListener('load', function () {
          el.dispatchEvent(new CustomEvent('init'));
          el.dispatchEvent(new CustomEvent('load'));
        });
        // postMessage bridge for completed/declined events from the iframe.
        window.addEventListener('message', function (event) {
          if (!event.data || typeof event.data !== 'object') return;
          if (event.data.docuseal_completed || event.data.type === 'docuseal-completed') {
            el.dispatchEvent(new CustomEvent('completed', { detail: event.data.payload || event.data }));
          }
          if (event.data.docuseal_declined || event.data.type === 'docuseal-declined') {
            el.dispatchEvent(new CustomEvent('decline', { detail: event.data.payload || event.data }));
          }
        });
      }

      var Form = class extends HTMLElement {
        connectedCallback() { mount(this); }
        static get observedAttributes() { return ['data-src']; }
        attributeChangedCallback() {
          if (this.querySelector('iframe')) {
            // Re-mount on src change.
            this.innerHTML = '';
            mount(this);
          }
        }
      };

      var Builder = class extends HTMLElement {
        connectedCallback() {
          // OSS builder fallback: link to the admin template editor instead
          // of trying to render the Pro inline builder. Pro users override
          // this controller entirely.
          this.innerHTML = '<p>Template builder is available in the admin UI.</p>';
        }
      };

      if (!window.customElements.get('docuseal-form')) {
        window.customElements.define('docuseal-form', Form);
      }
      if (!window.customElements.get('docuseal-builder')) {
        window.customElements.define('docuseal-builder', Builder);
      }
    })();
  JAVASCRIPT

  def show
    headers['Content-Type'] = 'application/javascript'
    headers['Cache-Control'] = 'public, max-age=300'
    self.response_body = EMBED_SCRIPT
    self.status = 200
  end
end
