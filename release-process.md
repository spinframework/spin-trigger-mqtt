# Cutting a new release of the Spin MQTT trigger plugin

To cut a new release of the MQTT trigger plugin, you will need to do the following:

1. Confirm that [CI is green](https://github.com/spinframework/spin-trigger-mqtt/actions) for the commit selected to be tagged and released.

2. Change the version number in [Cargo.toml](./Cargo.toml) and [spin-pluginify.toml](./spin-pluginify.toml) and run `cargo build --release`.

3. Create a pull request with these changes and merge once approved.

4. Checkout the commit with the version bump from above.

5. Create and push a new tag with a `v` and then the version number.

    As an example, via the `git` CLI:

    ```
    # Create a GPG-signed and annotated tag
    git tag -s -m "Spin MQTT Trigger v0.2.0" v0.2.0

    # Push the tag to the remote corresponding to spinframework/spin-trigger-mqtt (here 'origin')
    git push origin v0.2.0
    ```

6. Pushing the tag upstream will trigger the [release action](https://github.com/spinframework/spin-trigger-mqtt/actions/workflows/release.yml).
    - The release build will create the packaged versions of the plugin, the updated plugin manifest and a checksums file
    - These assets are uploaded to a new GitHub release for the pushed tag
    - Release notes are auto-generated but edit as needed especially around breaking changes or other notable items
  
7. Create a PR in the [spinframework/spin-plugins](https://github.com/spinframework/spin-plugins) repository with the [updated manifest](https://github.com/spinframework/spin-plugins/tree/main/manifests/mqtt-trigger).

8. If applicable, create PR(s) or coordinate [documentation](https://github.com/spinframework/spin-docs) needs, e.g. for new features or updated functionality.