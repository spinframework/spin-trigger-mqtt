pub use spin_mqtt_macro::mqtt_component;

#[doc(hidden)]
pub mod wit {
    #![allow(missing_docs)]

    wit_bindgen::generate!({
        world: "spin-mqtt-sdk",
        path: "..",
    });
}

#[doc(hidden)]
pub use wit_bindgen;

#[doc(inline)]
pub use wit::spin::mqtt_trigger::spin_mqtt_types::{Error, Metadata, Payload};
