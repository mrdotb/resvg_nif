
use std::path;
use rustler::{NifStruct, NifResult};
use usvg::{fontdb, TreeParsing, TreeTextToPath};

mod atoms {
    rustler::atoms! {
      ok,
      error
    }
}

#[derive(NifStruct)]
#[module = "Resvg.Options"]
pub struct Options {
    width: Option<u32>,
    height: Option<u32>,
    // zoom: Option<f32>,
    // dpi: u32,
    // background: Option<svgtypes::Color>,

    // languages: Vec<String>,
    // shape_rendering: usvg::ShapeRendering,
    // text_rendering: usvg::TextRendering,
    // image_rendering: usvg::ImageRendering,
    // resources_dir: Option<path::PathBuf>,

    // font_family: Option<String>,
    // font_size: u32,
    // serif_family: Option<String>,
    // sans_serif_family: Option<String>,
    // cursive_family: Option<String>,
    // fantasy_family: Option<String>,
    // monospace_family: Option<String>,
    // font_files: Vec<path::PathBuf>,
    // font_dirs: Vec<path::PathBuf>,
    skip_system_fonts: bool
}

#[rustler::nif]
pub fn svg_to_png(svg_path: String, png_path: String, options: Options) -> rustler::Atom {
    let rtree = {
        let mut opt = usvg::Options::default();
        // Get file's absolute directory.
        opt.resources_dir = std::fs::canonicalize(&svg_path)
            .ok()
            .and_then(|p| p.parent().map(|p| p.to_path_buf()));

        let mut fontdb = fontdb::Database::new();
        fontdb.load_system_fonts();

        let svg_data = std::fs::read(&svg_path).unwrap();
        let mut tree = usvg::Tree::from_data(&svg_data, &opt).unwrap();
        tree.convert_text(&fontdb);
        resvg::Tree::from_usvg(&tree)
    };

    let pixmap_size = rtree.size.to_int_size();
    let mut pixmap = tiny_skia::Pixmap::new(pixmap_size.width(), pixmap_size.height()).unwrap();
    rtree.render(tiny_skia::Transform::default(), &mut pixmap.as_mut());
    pixmap.save_png(&png_path).unwrap();
    atoms::ok()
}

#[rustler::nif]
pub fn list_fonts(options: Options) -> NifResult<Vec<String>> {
    let fontdb = load_fonts(options);

    let font_info_strings: Vec<String> = fontdb.faces()
        .filter_map(|face| {
            if let fontdb::Source::File(ref path) = &face.source {
                let families: Vec<_> = face
                    .families
                    .iter()
                    .map(|f| format!("{} ({}, {})", f.0, f.1.primary_language(), f.1.region()))
                    .collect();

                Some(format!(
                    "{}: '{}', {}, {:?}, {:?}, {:?}",
                    path.display(),
                    families.join("', '"),
                    face.index,
                    face.style,
                    face.weight.0,
                    face.stretch
                ))
            } else {
                None
            }
        })
        .collect();

    Ok(font_info_strings)
}

fn load_fonts(options: Options) -> fontdb::Database {
    let mut fontdb = fontdb::Database::new();
    if !options.skip_system_fonts {
        fontdb.load_system_fonts();
    }

    // for path in &options.font_files {
    //     if let Err(e) = fontdb.load_font_file(path) {
    //         log::warn!("Failed to load '{}' cause {}.", path.display(), e);
    //     }
    // }

    // for path in &args.font_dirs {
    //     fontdb.load_fonts_dir(path);
    // }

    // let take_or =
    //     |family: Option<String>, fallback: &str| family.unwrap_or_else(|| fallback.to_string());

    // fontdb.set_serif_family(take_or(args.serif_family.take(), "Times New Roman"));
    // fontdb.set_sans_serif_family(take_or(args.sans_serif_family.take(), "Arial"));
    // fontdb.set_cursive_family(take_or(args.cursive_family.take(), "Comic Sans MS"));
    // fontdb.set_fantasy_family(take_or(args.fantasy_family.take(), "Impact"));
    // fontdb.set_monospace_family(take_or(args.monospace_family.take(), "Courier New"));

    fontdb
}

rustler::init!("Elixir.Resvg.Native", [svg_to_png, list_fonts]);
