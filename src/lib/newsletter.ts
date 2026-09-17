// ABOUTME: Newsletter sign-up logic shared by the /newsletter page and its unit tests:
// ABOUTME: validation, the HubSpot form submission payload, and reading HubSpot's reply.

// Plain type-only syntax on purpose: Node runs this file directly in the unit tests by
// stripping the types, which does not support enums, namespaces or parameter properties.

export interface FieldError {
  field: 'email' | 'consent';
  kind: 'required' | 'invalid';
}

export type SubmitResult =
  | { ok: true }
  | { ok: false; field: 'email'; kind: 'invalid' }
  | { ok: false; kind: 'error' };

// Deliberately loose: one @, something on both sides, a dot in the domain. HubSpot does
// the real check and answers INVALID_EMAIL, which readResponse maps to the same message.
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// HubSpot's public form endpoint. No API key: it only accepts submissions to forms
// that exist, so there is no secret to leak from a static page.
export function submitUrl(form: { portalId: string; formGuid: string }): string {
  return `https://api.hsforms.com/submissions/v3/integration/submit/${form.portalId}/${form.formGuid}`;
}

export function validate(input: { email: string; consent: boolean }): FieldError[] {
  const errors: FieldError[] = [];
  const email = input.email.trim();
  if (!email) errors.push({ field: 'email', kind: 'required' });
  else if (!EMAIL.test(email)) errors.push({ field: 'email', kind: 'invalid' });
  if (!input.consent) errors.push({ field: 'consent', kind: 'required' });
  return errors;
}

export function buildSubmission(input: {
  firstname: string;
  lastname: string;
  email: string;
  subscriptionTypeId: number;
  consentText: string;
  processingText: string;
  pageUri: string;
  pageName: string;
}) {
  // 0-1 is HubSpot's object type ID for contacts.
  const fields = (['firstname', 'lastname', 'email'] as const)
    .map((name) => ({ objectTypeId: '0-1', name, value: input[name].trim() }))
    .filter((f) => f.value !== '');

  return {
    fields,
    context: { pageUri: input.pageUri, pageName: input.pageName },
    // The form's data privacy option is "implicit processing consent and individual
    // checkboxes for communications": submitting consents to processing, and the
    // newsletter needs its own ticked box. HubSpot records both texts with the contact,
    // which is the evidence of consent CASL asks for.
    legalConsentOptions: {
      consent: {
        consentToProcess: true,
        text: input.processingText,
        communications: [
          { value: true, subscriptionTypeId: input.subscriptionTypeId, text: input.consentText },
        ],
      },
    },
  };
}

export function readResponse(status: number, body: unknown): SubmitResult {
  if (status === 200) return { ok: true };
  const errors = (body as { errors?: { errorType?: string }[] } | null)?.errors ?? [];
  if (errors.some((e) => e.errorType === 'INVALID_EMAIL' || e.errorType === 'BLOCKED_EMAIL')) {
    return { ok: false, field: 'email', kind: 'invalid' };
  }
  return { ok: false, kind: 'error' };
}
