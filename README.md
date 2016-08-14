#Conto

##Description

Conto is an open source minimalistic finance manager for OS X originally written by [Nicola Vitacolonna](https://users.dimi.uniud.it/~nicola.vitacolonna/software/conto/) in 2002. Development was discontinued some time in 2004 and the project has been dormant since.

This fork was created with the intention of modernizing the project and adding new features while maintaining the original's lightweight, focused spirit.

##Building
Just clone the repository, open the Xcode project, and build. No dependencies necessary.

##Roadmap

* `1.2.5`: Basic maintanence release. Fixes deprecations and compiler warnings.
* `1.3.0`: Fixes unsafe code and out of bounds issues
* `1.5.0`: UI cleanup and modernization as far as possible while targeting OS X 10.4. Last release to support PowerPC and versions of OS X below 10.7.
* `2.0.0`: Major refactor, migrating codebase to ARC and raising deployment target to OS X 10.7. May also include large UI changes.
* `2.x.x`: Undetermined