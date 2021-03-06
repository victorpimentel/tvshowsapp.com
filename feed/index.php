<?php

header('Content-Type: application/rss+xml; charset=ISO-8859-1');

ob_start();   // start the output buffer

$cachetime = 2 * 60 * 60; // 2 hours
$flush = false;

// filter=Eureka&userName=eztv
if ($_SERVER['QUERY_STRING']!='') {
  $cachefile = dirname($_SERVER['SCRIPT_FILENAME']).'/cache/cache_'.md5(str_replace('&flush=1', '', $_SERVER['QUERY_STRING'])).'.xml';
} else {
  echo "Nothing to see here";
  exit;
}

// Serve from the cache if it is younger than $cachetime
if (file_exists($cachefile) && (time() - $cachetime < filemtime($cachefile)) && !$_GET['flush']) {
  readfile($cachefile);
  echo "<!-- Cached: " . str_replace(dirname($cachefile)."/cache_","",$cachefile) . " -->";
  exit;
}

$normal_pipe = "c6003d4834d77b0fdde620ce38c848ad";
$strict_pipe = "e382304dd89b1aa3fbd9beae4764986a";

if ($_GET['strict']) {
  $pipe = $strict_pipe;
} else {
  $pipe = $normal_pipe;
}

$ch = curl_init("http://pipes.yahoo.com/pipes/pipe.run?_id=".$pipe."&_render=rss&".$_SERVER['QUERY_STRING']);

curl_exec($ch);
curl_close($ch);

$fp = fopen($cachefile, 'w'); // open the cache file for writing

fwrite($fp, ob_get_contents()); // save the contents of output buffer to the file
fclose($fp); // close the file

ob_end_flush(); // Send the output to the browser

?>
