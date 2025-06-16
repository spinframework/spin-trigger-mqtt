    #[tokio::test]
    async fn spin_mqtt_trigger_app_test() -> Result<()> {
        use std::time::Duration;
        let mqtt_port = 1883;
        let message = "MESSAGE";
        let iterations = 5;

        // Publish a message to the emqx broker
        let mut mqttoptions = rumqttc::MqttOptions::new("123", "127.0.0.1", forward_port);
        mqttoptions.set_keep_alive(std::time::Duration::from_secs(1));

        let (client, mut eventloop) = rumqttc::AsyncClient::new(mqttoptions, 10);
        client
            .subscribe(
                "containerd-shim-spin/mqtt-test-17h24d",
                rumqttc::QoS::AtMostOnce,
            )
            .await
            .unwrap();

        // Publish a message several times for redundancy
        tokio::task::spawn(async move {
            for _i in 0..iterations {
                client
                    .publish(
                        "containerd-shim-spin/mqtt-test-17h24d",
                        rumqttc::QoS::AtLeastOnce,
                        false,
                        message.as_bytes(),
                    )
                    .await
                    .unwrap();
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
        });
        tokio::time::sleep(Duration::from_secs(5)).await;

        // Poll the event loop to ensure messages are published
        for _i in 0..iterations {
            eventloop.poll().await?;
        }
        thread::sleep(time::Duration::from_secs(5));

        // Ensure that the message was received and logged by the spin app
        let log = get_logs_by_label("app=spin-mqtt-message-logger").await?;
        assert!(log.contains(message));
        Ok(())
    }