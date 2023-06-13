// use rustler::{Env};
use usvg::{fontdb, TreeParsing, TreeTextToPath};

mod atoms {
    rustler::atoms! {
      ok,
      error
    }
}

#[rustler::nif]
pub fn convert(input: String, output: String) -> rustler::Atom {
    let rtree = {
        let mut opt = usvg::Options::default();
        // Get file's absolute directory.
        opt.resources_dir = std::fs::canonicalize(&input)
            .ok()
            .and_then(|p| p.parent().map(|p| p.to_path_buf()));

        let mut fontdb = fontdb::Database::new();
        fontdb.load_system_fonts();

        let svg_data = std::fs::read(&input).unwrap();
        let mut tree = usvg::Tree::from_data(&svg_data, &opt).unwrap();
        tree.convert_text(&fontdb);
        resvg::Tree::from_usvg(&tree)
    };

    let pixmap_size = rtree.size.to_int_size();
    let mut pixmap = tiny_skia::Pixmap::new(pixmap_size.width(), pixmap_size.height()).unwrap();
    rtree.render(tiny_skia::Transform::default(), &mut pixmap.as_mut());
    pixmap.save_png(&output).unwrap();
    atoms::ok()
}

rustler::init!("Elixir.Resvg.Native", [convert]);
