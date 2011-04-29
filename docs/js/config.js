/**
* This is the configuration file. Any modules / services use in the apps may require this config module.
*
* Feel free to make any change to options you want there.
* 
*/
define({
  // file extension of wiki files, usually md
  ext: '.md',

  // path to the wiki folder, by defaults it is wiki-upstream and points to a git submodule
  baseUrl: './wiki-upstream/',

  //default file
  baseFile: 'Home',

  // path to the wiki folder, by defaults it is wiki-upstream and points to a git submodule
  wikiUrl: '//github.com/victorpimentel/TVShows/wiki/',

  // File of the wiki, needs a manual update to any new file (or file deletion)
  // In the perspective of a datasource that uses the github api (on real repos onlt, repos wikis are not part of the api yet),
  // we wouldn't need this anymore
  files: [
    "Home.md",
    "Contribute.md"
  ]
});