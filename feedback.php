<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
        "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <title>JRFeedback</title>
</head>
<body>

<p>This page not intended for humans. Thanks for playing, though.</p>

<?php

if (array_key_exists('feedback', $_REQUEST)) {
  $feedbackType = $_REQUEST['feedbackType'];
  $appName = $_REQUEST['appName'];
  $appVersion = $_REQUEST['version'];

  if ($feedbackType == 'BUG') {
    $feedbackEmail = 'tender2+c680c334090f7818084091fc315fab112f57e08cc@tenderapp.com';
  } else if ($feedbackType == 'SUPPORT') {
    $feedbackEmail = 'tender2+c2868c7ea4c4dbfdbc3ebdbe2f4f61193b813f15f@tenderapp.com';
  } else {
    $feedbackEmail = 'tender2+c1f0fe10c8ace6de7dc2f8a852551231dc42cba39@tenderapp.com';
  }

  // if they choose not to give us their email, I will use my own
  // if I left the email blank it would come from 
  // suppressed@auma.pair.com or anonymous@auma.pair.com
  // FogBugz would try to send them an email and generate another 
  // ticket telling me "Undelivered Mail Returned to Sender"

  // Check for well formatted email address, if it's OK use their address in the "from" header, else
  // use generic support address
  if (eregi('^[a-zA-Z0-9._-]+@[a-zA-Z0-9-]+\.[a-zA-Z.]{2,5}$', $_REQUEST['email'])) {
    $email = $_REQUEST['email'];
    $name = $_REQUEST['name'];
  } else {
    $email = 'support@tvshowsapp.com';
    $name = 'Unknown Submitter';
  }
  $feedback = $_REQUEST['feedback'];

  $feedback = str_replace('What went wrong? Please explain what were you doing and, if possible, the steps to recreate the problem.', '', $feedback);
  $feedback = str_replace('How can we help you?', '', $feedback);
  $feedback = str_replace('If you want to request a new show, please check that it is currently airing and that EZTV releases it regularly. If you want to add another show that it is not on EZTV, please follow these instructions (también en español).', '', $feedback);
  $feedback = str_replace('What feature would you like to see implemented or improved?', '', $feedback);

  $bundleID = $_REQUEST['bundleID'];
  $systemProfile = $_REQUEST['systemProfile'];

  $headers = "From: admin@tvshowsapp.com\r\n" .
        "Reply-To: admin@tvshowsapp.com\\r\n" .
        'X-Mailer: PHP/' . phpversion();

  $msg .= "\n\n---------- Forwarded message ----------\n";
  $msg .= "From: \"$name\" <$email>\n";
  $msg .= "To: support@tvshowsapp.com\n\n\n";
  $msg .= "$feedback\n\n";
  $msg .= "$name\n";
//  $msg .= "\n--------\n\n";
//  $msg .= "System Profile: $systemProfile\n";

  mail($feedbackEmail, "Fwd: $appName $appVersion - $name", $msg, $headers);
}
?>

</body>
</html>
