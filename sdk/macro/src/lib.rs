use proc_macro::TokenStream;
use quote::quote;

const WIT_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../spin-mqtt.wit");

#[proc_macro_attribute]
pub fn mqtt_component(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let func = syn::parse_macro_input!(item as syn::ItemFn);
    let func_name = &func.sig.ident;

    if func.sig.asyncness.is_none() {
        return syn::Error::new_spanned(
            func.sig.fn_token,
            "the `#[mqtt_component]` function must be `async`",
        )
        .to_compile_error()
        .into();
    }

    let preamble = preamble();

    quote!(
        #func
        mod __spin_mqtt {
            mod preamble {
                #preamble
            }
            impl self::preamble::Guest for preamble::Mqtt {
                async fn handle_message(payload: ::spin_mqtt_sdk::Payload, metadata: ::spin_mqtt_sdk::Metadata) -> ::std::result::Result<(), ::spin_mqtt_sdk::Error> {
                    match super::#func_name(payload, metadata).await {
                        ::std::result::Result::Ok(()) => ::std::result::Result::Ok(()),
                        ::std::result::Result::Err(e) => {
                            eprintln!("{}", e);
                            ::std::result::Result::Err(::spin_mqtt_sdk::Error::Other(e.to_string()))
                        },
                    }
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
                "spin:mqtt-trigger/spin-mqtt-types@3.0.0": ::spin_mqtt_sdk,
            }
        });
        pub struct Mqtt;
        export!(Mqtt);
    }
}
