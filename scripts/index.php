<?php  
$ipas = glob('*.ipa');
$provisioningProfiles = glob('*.mobileprovision');
$plists = glob('*.plist');
$apks = glob('android/*.apk');

$host = $_SERVER['HTTP_HOST'];
$self = $_SERVER['PHP_SELF'];
$query = !empty($_SERVER['QUERY_STRING']) ? $_SERVER['QUERY_STRING'] : null;
$url = !empty($query) ? "http://$host$self?$query" : "http://$host$self";
$url = dirname($url).'/';
echo $url;

     $sr = $url;
     $provisioningProfile = $sr . $provisioningProfiles[0];
      $ipa = $sr . $ipas[0];
       $itmsUrl = urlencode( $sr . 'index.php?plist=' . str_replace( '.plist', '', $plists[0] ) );
          if ($_GET['plist']) {
           $plist = file_get_contents( dirname(__FILE__)  . DIRECTORY_SEPARATOR  . preg_replace( '/![A-Za-z0-9-_]/i', '', $_GET['plist']) . '.plist' );
            $plist = str_replace('_URL_', $ipa, $plist);
             header('content-type: application/xml');
            echo $plist;
            die(); 
          }   ?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 
<html> 
  <head> 
    <title>Install iOS App
    </title> 
    <style type="text/css">  li { padding: 1em; }  
    </style> 
  </head> 
  <body> 
    <ul> 
      <li>
      <a href="<? echo $provisioningProfile; ?>">Install Team Provisioning File</a>
      </li> 
      <li>
      <a href="itms-services://?action=download-manifest&url=<? echo $sr.$plists[0]; ?>"> Install Application</a>
      </li> 
      <li>
      <a href="<? echo $sr.$apks[0]; ?>">Download Android application</a>
      </li> 
    </ul> 
  </body> 
</html>