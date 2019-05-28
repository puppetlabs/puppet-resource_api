## Implementing the transport - Exercise

Implement a `request_debug` option that can be toggled on to create additional debug output on each request. You will not need concepts that you haven't yet seen in this tutorial, and basic programing skills. If you get stuck, have a look at some hints below, or [the finished file](TODO).

## Hints

* A toggle option can be created with the `Boolean` (`true` or `false`) data type. Add it to the `connection_info` in the transport schema.

* Make it an `Optional[Boolean]` so that users who do not require request debugging do not have to specify the value.

* To remember the value passed in from the user, store `connection_info[:request_debug]` in a `@request_debug` variable.

* In the `hue_get` and `hue_put` methods add `context.debug(message)` calls showing the method's arguments.

* Make the debugging optional based on the user's input by appending `if @request_debug` to each logging statement.

# Next Up

Now that the transport can talk to the remote target, it's time to [implement a provider](./06-implementing-the-provider.md).
