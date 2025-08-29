use proc_macro::TokenStream;
use quote::quote;

const WIT_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../spin-mqtt.wit");

#[proc_macro_attribute]
pub fn mqtt_component(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let func = syn::parse_macro_input!(item as syn::ItemFn);
    let func_name = &func.sig.ident;
    let await_postfix = func.sig.asyncness.map(|_| quote!(.await));
    let preamble = preamble();

    quote!(
        #func
        mod __spin_mqtt {
            mod preamble {
                #preamble
            }
            impl self::preamble::Guest for preamble::Mqtt {
                fn handle_message(payload: ::spin_mqtt_sdk::Payload, metadata: ::spin_mqtt_sdk::Metadata) -> ::std::result::Result<(), ::spin_mqtt_sdk::Error> {
                    ::spin_mqtt_sdk::executor::run(async move {
                        match super::#func_name(payload, metadata)#await_postfix {
                            ::std::result::Result::Ok(()) => ::std::result::Result::Ok(()),
                            ::std::result::Result::Err(e) => {
                                eprintln!("{}", e);
                                ::std::result::Result::Err(::spin_mqtt_sdk::Error::Other(e.to_string()))
                            },
                        }
                    })
                }
            }
        }
    ).into()
}

fn preamble() -> proc_macro2::TokenStream {
    let world = "spin-mqtt";
    quote! {
        #![allow(missing_docs)]
        ::spin_mqtt_sdk::wit_bindgen::generate!({
            world: #world,
            path: #WIT_PATH,
            runtime_path: "::spin_mqtt_sdk::wit_bindgen::rt",
            with: {
                "spin:mqtt-trigger/spin-mqtt-types": ::spin_mqtt_sdk,
            }
        });
        pub struct Mqtt;
        export!(Mqtt);
    }
}
