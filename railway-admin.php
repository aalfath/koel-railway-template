<?php
// Replaces Koel's default first-admin password (admin@koel.dev / KoelIsCool) with KOEL_ADMIN_PASSWORD,
// and the e-mail with KOEL_ADMIN_EMAIL. It only acts while that account still has the default password,
// so changes made later in Koel's web UI are never overwritten.

require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

$user = User::query()->where('email', User::FIRST_ADMIN_EMAIL)->first();

if (!$user || !Hash::check(User::FIRST_ADMIN_PASSWORD, $user->password)) {
    echo "Koel admin: default password not in use, nothing to change\n";
    exit(0);
}

$password = (string) getenv('KOEL_ADMIN_PASSWORD');
$email = trim((string) getenv('KOEL_ADMIN_EMAIL')) ?: User::FIRST_ADMIN_EMAIL;

if (strlen($password) < 10 || $password === User::FIRST_ADMIN_PASSWORD) {
    fwrite(STDERR, "KOEL_ADMIN_PASSWORD must be set (10+ characters); refusing to start with the default admin password\n");
    exit(1);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "KOEL_ADMIN_EMAIL is not a valid e-mail address\n");
    exit(1);
}

$user->password = $password; // the model's "hashed" cast hashes it
$user->email = $email;
$user->save();

echo "Koel admin: set the password for {$email} from KOEL_ADMIN_PASSWORD\n";
