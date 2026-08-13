// ABOUTME: Build-time endpoint that ships the contact-form destination into dist/api/contact.json,
// ABOUTME: so contact.php reads it at runtime from the single source src/data/contact.json (phase-2b §6).
import contact from '../../data/contact.json';

export const GET = () =>
  new Response(JSON.stringify({ contactFormTo: contact.contactFormTo }), {
    headers: { 'Content-Type': 'application/json' },
  });
