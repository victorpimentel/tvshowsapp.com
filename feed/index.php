<?php

ob_start();   // start the output buffer

$cachetime = 6 * 60 * 60; // 6 hours

// filter=Eureka&userName=eztv
if ($_SERVER['QUERY_STRING']!='') {
  $cachefile = dirname($_SERVER['SCRIPT_FILENAME']).'/cache/cache_'.md5($_SERVER['QUERY_STRING']).".xml";
} else {
  echo "Nothing to see here";
  exit;
}

// Serve from the cache if it is younger than $cachetime
if (file_exists($cachefile) && (time() - $cachetime < filemtime($cachefile))) {
  readfile($cachefile);
  exit;
}

$ch = curl_init("http://pipes.yahoo.com/pipes/pipe.run?_id=c6003d4834d77b0fdde620ce38c848ad&_render=rss&".$_SERVER['QUERY_STRING']);

curl_exec($ch);
curl_close($ch);

$fp = fopen($cachefile, 'w'); // open the cache file for writing

fwrite($fp, ob_get_contents()); // save the contents of output buffer to the file
fclose($fp); // close the file
ob_end_flush(); // Send the output to the browser

?>
