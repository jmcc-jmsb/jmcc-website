// ABOUTME: Unit tests for the newsletter sign-up logic: validation, the HubSpot payload, and
// ABOUTME: reading HubSpot's reply. Run: node --test tests/newsletter.test.ts (no dependencies).

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validate, buildSubmission, readResponse, submitUrl } from '../src/lib/newsletter.ts';

const texts = {
  consentText: 'I agree to receive the newsletter.',
  processingText: 'By signing up you allow JMCC to store your details.',
};

test('submitUrl points at HubSpot’s form submission endpoint', () => {
  assert.equal(
    submitUrl({ portalId: '341993627', formGuid: 'f54026b2-54b7-41ab-81bb-743c0f5864c2' }),
    'https://api.hsforms.com/submissions/v3/integration/submit/341993627/f54026b2-54b7-41ab-81bb-743c0f5864c2',
  );
});

test('validate: a complete sign-up has no errors', () => {
  assert.deepEqual(validate({ email: 'a@b.ca', consent: true }), []);
});

test('validate: email is required', () => {
  assert.deepEqual(validate({ email: '   ', consent: true }), [{ field: 'email', kind: 'required' }]);
});

test('validate: a malformed email is rejected', () => {
  for (const email of ['nope', 'a@b', 'a b@c.ca', '@b.ca']) {
    assert.deepEqual(validate({ email, consent: true }), [{ field: 'email', kind: 'invalid' }], email);
  }
});

test('validate: consent is required, and every problem is reported at once', () => {
  assert.deepEqual(validate({ email: '', consent: false }), [
    { field: 'email', kind: 'required' },
    { field: 'consent', kind: 'required' },
  ]);
});

test('buildSubmission: sends trimmed fields and the consent HubSpot requires', () => {
  const payload = buildSubmission({
    firstname: '  Marie ',
    lastname: ' Tremblay',
    email: ' marie@example.ca ',
    subscriptionTypeId: 2207787660,
    pageUri: 'https://www.wecompete.ca/fr/newsletter/',
    pageName: 'Infolettre | JMCC',
    ...texts,
  });
  assert.deepEqual(payload, {
    fields: [
      { objectTypeId: '0-1', name: 'firstname', value: 'Marie' },
      { objectTypeId: '0-1', name: 'lastname', value: 'Tremblay' },
      { objectTypeId: '0-1', name: 'email', value: 'marie@example.ca' },
    ],
    context: { pageUri: 'https://www.wecompete.ca/fr/newsletter/', pageName: 'Infolettre | JMCC' },
    legalConsentOptions: {
      consent: {
        consentToProcess: true,
        text: texts.processingText,
        communications: [{ value: true, subscriptionTypeId: 2207787660, text: texts.consentText }],
      },
    },
  });
});

test('buildSubmission: leaves out names that were not given', () => {
  const payload = buildSubmission({
    firstname: '',
    lastname: '  ',
    email: 'a@b.ca',
    subscriptionTypeId: 1,
    pageUri: 'u',
    pageName: 'n',
    ...texts,
  });
  assert.deepEqual(payload.fields, [{ objectTypeId: '0-1', name: 'email', value: 'a@b.ca' }]);
});

test('readResponse: a 200 is a successful sign-up', () => {
  assert.deepEqual(readResponse(200, { inlineMessage: 'Thanks' }), { ok: true });
});

test('readResponse: HubSpot rejecting the address is an email error', () => {
  for (const errorType of ['INVALID_EMAIL', 'BLOCKED_EMAIL']) {
    const body = { status: 'error', errors: [{ errorType, message: 'x' }] };
    assert.deepEqual(readResponse(400, body), { ok: false, field: 'email', kind: 'invalid' }, errorType);
  }
});

test('readResponse: anything else is a general failure', () => {
  const captcha = { status: 'error', errors: [{ errorType: 'FORM_HAS_RECAPTCHA_ENABLED' }] };
  assert.deepEqual(readResponse(400, captcha), { ok: false, kind: 'error' });
  assert.deepEqual(readResponse(500, null), { ok: false, kind: 'error' });
  assert.deepEqual(readResponse(404, { message: 'not found' }), { ok: false, kind: 'error' });
});
