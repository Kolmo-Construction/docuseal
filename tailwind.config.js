// Theme colors are env-overridable so the same image can be deployed
// branded for multiple tenants (or unbranded).
//
//   PRIMARY_COLOR    accent/CTA color (also used for signature-field highlights)
//   SECONDARY_COLOR  supporting color
//   NEUTRAL_COLOR    dark text / icon color
//   BASE_100_COLOR   page background
//   BASE_200_COLOR   subtle bg variations
//   BASE_300_COLOR   borders
//
// Defaults preserve upstream DocuSeal beige/pink theme.
const env = (key, fallback) => process.env[key] && process.env[key].length ? process.env[key] : fallback

module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: env('PRIMARY_COLOR', '#e4e0e1'),
          secondary: env('SECONDARY_COLOR', '#ef9fbc'),
          accent: env('ACCENT_COLOR', env('PRIMARY_COLOR', '#eeaf3a')),
          neutral: env('NEUTRAL_COLOR', '#291334'),
          'base-100': env('BASE_100_COLOR', '#faf7f5'),
          'base-200': env('BASE_200_COLOR', '#efeae6'),
          'base-300': env('BASE_300_COLOR', '#e7e2df'),
          'base-content': env('NEUTRAL_COLOR', '#291334'),
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
