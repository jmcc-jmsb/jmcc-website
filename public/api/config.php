<?php
// ABOUTME: Single source of configuration for the contact endpoint — addresses, limits, paths.
// ABOUTME: No secrets live here; the signing key is generated into STATE_DIR on first use.
declare(strict_types=1);

// --- Mail -------------------------------------------------------------------
// Recipient. Mirrors src/data/contact.json — keep the two in step.
const CONTACT_TO = 'Info@wecompete.ca';

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
const STATE_DIR = '/home/jmcc/form-state';

// --- Anti-spam --------------------------------------------------------------
const RATE_LIMIT_MAX = 5;          // submissions ...
const RATE_LIMIT_WINDOW = 3600;    // ... per IP per hour
const MIN_FILL_SECONDS = 3;        // faster than this is a bot
const MAX_TOKEN_AGE = 7200;        // form token expires after 2 hours

// --- Field limits -----------------------------------------------------------
const LIMITS = [
    'name' => 120,
    'email' => 254,
    'subject' => 200,
    'message' => 5000,
];
