#WP DevOps Changelog

## 2.1.1
- Fix it so there are no empty build messages
- Fix init.php run by Composer to not strip lines in .gitignore.     

## 2.1.0
- Support for transforming paths in Composer autoloader
- Added `.web_root` to `.source`, `.deploy` and `.hosts` in `project.json`
- Moved from GitHub managed deploy count to CircleCI-managed build number.
    - Eliminated use of `deploy-lock` 
    - Changed from using`DEPLOY` file to using `BUILD` file, like earlier WP DevOps.
- Removed CircleCI caching in the config.yml to reduce change of errors.     

## 2.0.0
- Support for CircleCI 2.0

 


