<?php
// ABOUTME: Contact form endpoint — validates, rate-limits, and mails general enquiries.
// ABOUTME: GET issues a signed timestamp for the timing check; POST submits. JSON in, JSON out.
declare(strict_types=1);

// Local/staging overrides load FIRST: PHP constants cannot be redefined, so config.php
// only defines what this file has not already set. Gitignored, never deployed, absent
// in production — where config.php's values stand unchanged.
if (is_readable(__DIR__ . '/config.local.php')) {
    require __DIR__ . '/config.local.php';
}
require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');

// User-facing strings only. Anything diagnostic goes to the log, never to the client:
// a validation message that names the failing rule tells a spammer how to pass it.
const MESSAGES = [
    'en' => [
        'ok' => 'Thank you — your message has been sent. We’ll get back to you soon.',
        'invalid' => 'Please check the highlighted fields and try again.',
        'email' => 'Please enter a valid email address.',
        'rate' => 'Too many messages from this connection. Please try again later.',
        'expired' => 'This form has been open too long. Please reload the page and try again.',
        'server' => 'Something went wrong on our end. Please email us directly at ' . CONTACT_TO . '.',
        'method' => 'Method not allowed.',
    ],
    'fr' => [
        'ok' => 'Merci — votre message a été envoyé. Nous vous répondrons sous peu.',
        'invalid' => 'Veuillez vérifier les champs indiqués et réessayer.',
        'email' => 'Veuillez saisir une adresse courriel valide.',
        'rate' => 'Trop de messages depuis cette connexion. Veuillez réessayer plus tard.',
        'expired' => 'Ce formulaire est ouvert depuis trop longtemps. Rechargez la page et réessayez.',
        'server' => 'Une erreur est survenue de notre côté. Écrivez-nous directement à ' . CONTACT_TO . '.',
        'method' => 'Méthode non autorisée.',
    ],
];

function lang_of(mixed $v): string
{
    return $v === 'fr' ? 'fr' : 'en';
}

function respond(int $status, array $body): never
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(int $status, string $lang, string $key, array $extra = []): never
{
    respond($status, ['ok' => false, 'error' => MESSAGES[$lang][$key]] + $extra);
}

/** Logs to the state dir. Never surfaces to the client. */
function log_line(string $msg): void
{
    @file_put_contents(
        STATE_DIR . '/contact.log',
        sprintf("[%s] %s\n", gmdate('c'), $msg),
        FILE_APPEND | LOCK_EX
    );
}

/**
 * Enforces the retention the privacy policy publishes: log lines past
 * LOG_RETENTION_DAYS are dropped and spent rate-limit counters are deleted. Nothing
 * else prunes the state dir — no cron on this host — so it happens inline, at most
 * once a day. Silent on failure: housekeeping must never fail a submission.
 */
function prune_state(): void
{
    $now = time();
    $stamp = STATE_DIR . '/last-prune';
    if ((int) @filemtime($stamp) > $now - 86400) {
        return;
    }
    if (!@touch($stamp)) {
        return;  // state dir missing or read-only; signing_key() reports that properly
    }

    $log = STATE_DIR . '/contact.log';
    $lines = @file($log);
    if (is_array($lines)) {
        $cutoff = $now - LOG_RETENTION_DAYS * 86400;
        // Lines are "[ISO-8601] message". One we cannot date is kept, not guessed at.
        $keep = array_filter($lines, static function (string $line) use ($cutoff): bool {
            $end = strpos($line, ']');
            if (strncmp($line, '[', 1) !== 0 || $end === false) {
                return true;
            }
            $at = strtotime(substr($line, 1, $end - 1));
            return $at === false || $at >= $cutoff;
        });
        if (count($keep) !== count($lines)) {
            @file_put_contents($log, implode('', $keep), LOCK_EX);
        }
    }

    // A counter older than the window is spent, and each one is a hashed IP.
    foreach (glob(STATE_DIR . '/rate-*.json') ?: [] as $file) {
        if ((int) @filemtime($file) < $now - RATE_LIMIT_WINDOW) {
            @unlink($file);
        }
    }
}

/**
 * Signing key for form tokens. Generated on first use so no secret is ever
 * committed. Lives outside the document root, so a deploy cannot clobber it.
 */
function signing_key(): string
{
    if (!is_dir(STATE_DIR)) {
        // Should already exist (see MAINTENANCE.md). Try once, then fail loudly —
        // silently skipping the timing check would disable spam protection.
        @mkdir(STATE_DIR, 0700, true);
        if (!is_dir(STATE_DIR)) {
            throw new RuntimeException('state dir missing: ' . STATE_DIR);
        }
    }
    $path = STATE_DIR . '/contact.key';
    $key = @file_get_contents($path);
    if ($key !== false && strlen($key) >= 32) {
        return $key;
    }
    $key = random_bytes(32);
    if (@file_put_contents($path, $key, LOCK_EX) === false) {
        throw new RuntimeException('cannot write signing key to ' . STATE_DIR);
    }
    @chmod($path, 0600);
    return $key;
}

function client_ip(): string
{
    // Only REMOTE_ADDR is trustworthy here — X-Forwarded-For is client-settable
    // on shared cPanel hosting, so honouring it would make the rate limit bypassable.
    return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

/** True when this IP is still under the limit; records the attempt. */
function under_rate_limit(string $ip): bool
{
    $file = STATE_DIR . '/rate-' . hash('sha256', $ip) . '.json';
    $now = time();
    $hits = [];
    $raw = @file_get_contents($file);
    if ($raw !== false) {
        $decoded = json_decode($raw, true);
        if (is_array($decoded)) {
            $hits = array_filter($decoded, static fn($t) => is_int($t) && $t > $now - RATE_LIMIT_WINDOW);
        }
    }
    if (count($hits) >= RATE_LIMIT_MAX) {
        return false;
    }
    $hits[] = $now;
    @file_put_contents($file, json_encode(array_values($hits)), LOCK_EX);
    return true;
}

/** Rejects any value that would let a caller inject extra mail headers. */
function header_safe(string $v): bool
{
    return !preg_match('/[\r\n\0]/', $v);
}

/** mbstring is usually present on cPanel but is not guaranteed; degrade to bytes. */
function str_len(string $v): int
{
    return function_exists('mb_strlen') ? mb_strlen($v) : strlen($v);
}

prune_state();

// --- GET: issue a signed timestamp -----------------------------------------
// The site is statically generated, so the form cannot be stamped at build time
// without the stamp going stale. The page asks for one on load instead.
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'GET') {
    try {
        $ts = (string) time();
        respond(200, ['ts' => $ts, 'sig' => hash_hmac('sha256', $ts, signing_key())]);
    } catch (Throwable $e) {
        log_line('token: ' . $e->getMessage());
        fail(500, 'en', 'server');
    }
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: GET, POST');
    fail(405, 'en', 'method');
}

$raw = file_get_contents('php://input') ?: '';
$in = json_decode($raw, true);
if (!is_array($in)) {
    $in = $_POST;  // tolerate a plain form post, e.g. if JS failed to load
}

$lang = lang_of($in['lang'] ?? 'en');

// 1. Honeypot. A filled hidden field means a bot: report success and drop it,
//    so the bot has no signal to adapt to.
if (trim((string) ($in['website'] ?? '')) !== '') {
    log_line('honeypot from ' . client_ip());
    respond(200, ['ok' => true, 'message' => MESSAGES[$lang]['ok']]);
}

// 2. Timing check against the signed token.
$ts = (string) ($in['ts'] ?? '');
$sig = (string) ($in['sig'] ?? '');
try {
    $expected = hash_hmac('sha256', $ts, signing_key());
} catch (Throwable $e) {
    log_line('key: ' . $e->getMessage());
    fail(500, $lang, 'server');
}
if ($ts === '' || !ctype_digit($ts) || !hash_equals($expected, $sig)) {
    log_line('bad token from ' . client_ip());
    fail(400, $lang, 'expired');
}
$age = time() - (int) $ts;
if ($age < MIN_FILL_SECONDS) {
    log_line('too fast (' . $age . 's) from ' . client_ip());
    respond(200, ['ok' => true, 'message' => MESSAGES[$lang]['ok']]);
}
if ($age > MAX_TOKEN_AGE) {
    fail(400, $lang, 'expired');
}

// 3. Rate limit.
if (!under_rate_limit(client_ip())) {
    log_line('rate limited ' . client_ip());
    fail(429, $lang, 'rate');
}

// 4. Validate.
$fields = [];
$errors = [];
foreach (LIMITS as $key => $max) {
    $value = trim((string) ($in[$key] ?? ''));
    if ($value === '') {
        $errors[$key] = true;
    } elseif (str_len($value) > $max) {
        $errors[$key] = true;
    }
    $fields[$key] = $value;
}

if (!filter_var($fields['email'], FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = true;
}

// Values that end up in mail headers must not contain line breaks.
foreach (['name', 'email', 'subject'] as $key) {
    if (!header_safe($fields[$key])) {
        log_line('header injection attempt from ' . client_ip());
        $errors[$key] = true;
    }
}

if ($errors) {
    fail(422, $lang, isset($errors['email']) && count($errors) === 1 ? 'email' : 'invalid', [
        'fields' => array_keys($errors),
    ]);
}

// 5. Send.
$subject = SUBJECT_PREFIX . ' ' . $fields['subject'];
$body = implode("\n", [
    'Name:    ' . $fields['name'],
    'Email:   ' . $fields['email'],
    'Language:' . $lang,
    'Sent:    ' . gmdate('c'),
    '',
    $fields['message'],
    '',
    '--',
    'Sent from the contact form on ' . ($_SERVER['HTTP_HOST'] ?? 'wecompete.ca'),
]);

$headers = [
    'From: ' . sprintf('%s <%s>', CONTACT_FROM_NAME, CONTACT_FROM),
    'Reply-To: ' . sprintf('%s <%s>', $fields['name'], $fields['email']),
    'Content-Type: text/plain; charset=utf-8',
    'MIME-Version: 1.0',
];

// Encode so non-ASCII subjects survive and the header stays on one line.
$encodedSubject = '=?UTF-8?B?' . base64_encode($subject) . '?=';

if (MAIL_TRANSPORT === 'file') {
    // Local and staging: write the composed message instead of sending it, so the
    // headers and body can be asserted without a mail server in the loop.
    $sent = (bool) @file_put_contents(
        STATE_DIR . '/mail.log',
        sprintf(
            "=== %s ===\nTo: %s\nSubject: %s\n%s\n\n%s\n\n",
            gmdate('c'),
            CONTACT_TO,
            $encodedSubject,
            implode("\n", $headers),
            $body
        ),
        FILE_APPEND | LOCK_EX
    );
} else {
    // -f sets the envelope sender so SPF is evaluated against our own domain.
    $sent = @mail(CONTACT_TO, $encodedSubject, $body, implode("\r\n", $headers), '-f' . CONTACT_FROM);
}

if (!$sent) {
    log_line('mail() failed for ' . $fields['email']);
    fail(500, $lang, 'server');
}

log_line('sent from ' . $fields['email']);
respond(200, ['ok' => true, 'message' => MESSAGES[$lang]['ok']]);
