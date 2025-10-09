Demonstrate how to use Secret Manager secrets with the Google fabric module.

In particular, show how the fabric module doesn't store sensitive data in state if you use write_only_version.  But the random_password provider DOES store its result in state.  Although there is an ephemeral
version of random_password, it can't be used with the Secret Manager fabric module because secret version data is not passed as a variable than can be marked ephemeral=true
