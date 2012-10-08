# TPTentClient
**Elegant tent.io handling for Cocoa Touch**

> As this project is under early and active development, method signatures and functionality is subject to change.
> General feedback, bug reports and feature requests appreciated.

TPTentClient allows iOS applications to communicate with [tent.io](https://tent.io) servers using the [Tent protocol](https://tent.io/docs).

## Getting Started

An example application is included in the repository, demonstrating server discovery, authorization, retrieval and posting a status. 

Don't forget to pull down AFNetworking and SSToolkit with `git submodule update --init` to run the example.

## Requirements

TPTentClient requires Xcode 4.4 and the [iOS 5.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iOS5.html) SDK, as well as [AFNetworking](https://github.com/afnetworking/afnetworking) 1.0RC3 and [SSToolkit](https://github.com/samsoffes/sstoolkit) 1.0.1.

## Next Steps

TPTentClient currently supports a small subset of what's possible with Tent. There's lots to do, including:

- Documentation
- Better error handling
- Access to all [Tent API](https://tent.io/docs) endpoints
- Support Tent Server fallback during Discovery
- Support multiple authenticated servers at once 
- Enhanced delegate methods
- Support for Mac OS X and Cocoa

If you'd like to see a different feature or have found a bug, please [open an issue](https://github.com/followben/TPTentClient/issues) or [fork the repo](https://github.com/followben/TPTentClient/fork_select) and submit a pull request. If you'd just like to contribute, search for "TODO:"!

## Credits

TPTentClient created and maintained by [Ben Stovold](https://github.com/followben).

Special thanks to [all contributors](https://github.com/followben/TPTentClient/graphs/contributors). 

[Tent](https://github.com/tent) is the incredible work of the [Tent team](https://github.com/tent?tab=members), including [Daniel Siders](https://github.com/danielsiders) and [Jonathan Rudenberg](https://github.com/titanous).

AFNetworking and SSToolkit are thanks to [Mattt Thompson](http://github.com/mattt) and [Sam Soffes](https://github.com/samsoffes) respectively.

## Contact

Follow Ben on Tent.is ([^followben](https://followben.tent.is)) or visit [thoughtfulpixel.com](http://thoughtfulpixel.com)

## License

TPTentClient is available under the MIT license. See the LICENSE file for more info.