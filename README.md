confluence-soap
===============

Ruby client for Confluence's SOAP API

    http://<confluence-install>/wiki/rpc/soap-axis/confluenceservice-v2?wsdl

## Running the specs

First:
`cp config/confluence.yml.example config/confluence.yml`

Then edit `config/confluence.yml` to match your instance's settings.
You should create a separate confluence space for the specs to run
against, as running the specs will delete all pages in that space.

## Contributing to confluence-soap

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

### Credits
=======
[Ping Yu](https://github.com/pyu10055)

[Eric Himmelreich](https://github.com/rawsyntax)

[Intridea](http://www.intridea.com)


### Copyright

Copyright (c) 2014 Intridea. See LICENSE.txt for
further details.

