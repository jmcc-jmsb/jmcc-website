<?php
// ABOUTME: Single source of configuration for the contact endpoint — addresses, limits, paths.
// ABOUTME: No secrets live here; the signing key is generated into STATE_DIR on first use.
declare(strict_types=1);

// Values below use `defined() || define()` so config.local.php — loaded first by
// contact.php, gitignored, never deployed — can override them for staging and tests.
// PHP constants cannot be redefined, so this guard is what makes overriding possible.

// --- Mail -------------------------------------------------------------------
// Recipient. Read at runtime from contact.json beside this file — emitted at build
// from src/data/contact.json (contactFormTo), the single source of truth. The
// hardcoded fallback only applies if the JSON is missing or unreadable.
if (!defined('CONTACT_TO')) {
    $jmccContactJson = is_readable(__DIR__ . '/contact.json')
        ? json_decode((string) file_get_contents(__DIR__ . '/contact.json'), true)
        : null;
    define('CONTACT_TO', is_array($jmccContactJson) && !empty($jmccContactJson['contactFormTo'])
        ? (string) $jmccContactJson['contactFormTo']
        : 'info@wecompete.ca');
}

// Envelope sender. Must be an address ON the canonical domain: wecompete.ca now
// hosts both the site and the mailbox, so this is no longer a cross-domain send.
// Confirm with CASA IT (Ryan) that SPF for wecompete.ca authorises this server.
const CONTACT_FROM = 'website@wecompete.ca';
const CONTACT_FROM_NAME = 'JMCC Website';
const SUBJECT_PREFIX = '[JMCC Website]';

// --- Writable state ---------------------------------------------------------
// MUST live outside the document root. Deploys run `rsync --delete`, which wipes
// anything inside the deploy target — rate-limit counters and the signing key
// would reset on every deploy and the log would be lost.
// Create once by hand:  mkdir -p /home/jmcc/form-state && chmod 700 /home/jmcc/form-state
// JMCC_FORM_STATE overrides the path for staging and local testing; production
// leaves it unset and gets the default below.
defined('STATE_DIR') || define('STATE_DIR', getenv('JMCC_FORM_STATE') ?: '/home/jmcc/form-state');

// --- Anti-spam --------------------------------------------------------------
const RATE_LIMIT_MAX = 5;          // submissions ...
const RATE_LIMIT_WINDOW = 3600;    // ... per IP per hour
const MIN_FILL_SECONDS = 3;        // faster than this is a bot
const MAX_TOKEN_AGE = 7200;        // form token expires after 2 hours

// --- Retention --------------------------------------------------------------
// contact.log holds IP and email addresses, so it is personal information and cannot
// be kept forever. 365 days matches the "up to 12 months" the privacy policy publishes
// for logs — change both together, never one alone. Enforced by prune_state().
const LOG_RETENTION_DAYS = 365;

// --- Mail transport ---------------------------------------------------------
// 'mail' calls PHP mail(). 'file' writes the fully composed message to
// STATE_DIR/mail.log and sends nothing — that is what makes the message itself
// (headers, Reply-To, body) assertable without a mail server.
// Overridden by config.local.php, which is gitignored and never deployed.
defined('MAIL_TRANSPORT') || define('MAIL_TRANSPORT', 'mail');

// --- Field limits -----------------------------------------------------------
const LIMITS = [
    'name' => 120,
    'email' => 254,
    'subject' => 200,
    'message' => 5000,
];
