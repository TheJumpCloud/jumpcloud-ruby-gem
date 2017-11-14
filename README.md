jumpcloud-ruby-gem
==================

This repository is now deprecated. Please refer to the [jcapi-ruby](https://github.com/TheJumpCloud/jcapi-ruby) repository for the Ruby JumpCloud API Client.

---

The JumpCloud Ruby Gem is JumpCloud's first SDK, based on Ruby, and leveraging the JumpCloud system API. It allows you easily set up any server by adding it to any list of tags you like, settings the system name, and to help you terminate the server by being able to delete it from JumpCloud.

The JumpCloud Ruby Gem is made available under the Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/), and this is
a curated public project. We will be accepting pull requests going forward, provided they're well-tested and fit with the goal
of providing the easiest possible access to the JumpCloud system context API.

You can build the Gem yourself based on this repo, by doing:

```
gem build jumpcloud.gemspec
```

And then install it locally in your own gem repo:

```
gem install jumpcloud-0.3.0.gem
```

Or, you can install it from the rubygems.org repo, by simply running:

```
gem install jumpcloud
```

### Setting the system name

Setting the system name in JumpCloud can be done as follows:

```
require 'jumpcloud'

JumpCloud.set_system_name("new_system_name")
```

### Setting the tags for the system

Setting tags can be done either by tag name or by tag ID:

#### Setting by tag name

```
require 'jumpcloud'

JumpCloud.set_system_tags("Web Servers", "Databases")
```

#### Setting by tag ID

```
require 'jumpcloud'

JumpCloud.set_system_tags("52cda39217b0917a63000020", "52966eac53e890d008000f05")
```

### Deleting the system

This will delete the system from JumpCloud, and should be used prior to terminating an instance managed by JumpCloud:


```
require 'jumpcloud'

JumpCloud.delete_system()
```

### Setting multiple fields at one time

You can set multiple fields at a time, as well, and fields in excess of what can be set via other functions in the SDK. JumpCloud thanks Ryan Bachman (ryan.bachman@inin.com) at Interactive Intelligence for his submission.

```
jc = JumpCloud.new()

jc.update_settings({
"displayName" => "Foo-Server",
"allowSshPasswordAuthentication" => true,
"allowPublicKeyAuthentication" => true,
"allowSshRootLogin" => false,
"tags" => ['dev']
})
```

Please see the JumpCloud System Context API documentation (https://github.com/TheJumpCloud/SystemContextAPI) on the Systems and Tags APIs for more detail.
