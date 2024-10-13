// Based on https://github.com/RazrFalcon/resvg/blob/master/crates/resvg/src/main.rs

use rustler::{Decoder, Encoder, Env, NifResult, NifStruct, Term};
use std::path;
use usvg::{fontdb, ImageRendering, ShapeRendering, TextRendering};
use std::sync::Arc;

mod atoms {
    rustler::atoms! {
      ok,
      error
    }
}

#[derive(Clone, Copy, PartialEq, Debug)]
enum FitTo {
    /// Keep original size.
    Original,
    /// Scale to width.
    Width(u32),
    /// Scale to height.
    Height(u32),
    /// Scale to size.
    Size(u32, u32),
    /// Zoom by factor.
    Zoom(f32),
}

#[derive(Clone, PartialEq, Debug)]
enum InputFrom {
    File(path::PathBuf),
    Text,
    Empty,
}

impl FitTo {
    fn fit_to_size(&self, size: tiny_skia::IntSize) -> Option<tiny_skia::IntSize> {
        match *self {
            FitTo::Original => Some(size),
            FitTo::Width(w) => size.scale_to_width(w),
            FitTo::Height(h) => size.scale_to_height(h),
            FitTo::Size(w, h) => tiny_skia::IntSize::from_wh(w, h).map(|s| size.scale_to(s)),
            FitTo::Zoom(z) => size.scale_by(z),
        }
    }

    fn fit_to_transform(&self, size: tiny_skia::IntSize) -> tiny_skia::Transform {
        let size1 = size.to_size();
        let size2 = match self.fit_to_size(size) {
            Some(v) => v.to_size(),
            None => return tiny_skia::Transform::default(),
        };
        tiny_skia::Transform::from_scale(
            size2.width() / size1.width(),
            size2.height() / size1.height(),
        )
    }
}

macro_rules! try_or_return_elixir_err {
    ($expression:expr, $env:expr) => {
        match $expression.map_err(|e| e.to_string()) {
            Ok(val) => val,
            Err(err) => return Ok((atoms::error(), err).encode($env)),
        }
    };
}

#[derive(Clone)]
pub struct ShapeRenderingWrapper {
    value: ShapeRendering,
}

#[derive(Clone)]
pub struct TextRenderingWrapper {
    value: TextRendering,
}

#[derive(Clone)]
pub struct ImageRenderingWrapper {
    value: ImageRendering,
}

struct FontProperties {
    font_files: Vec<path::PathBuf>,
    font_dirs: Vec<path::PathBuf>,
    serif_family: Option<String>,
    sans_serif_family: Option<String>,
    cursive_family: Option<String>,
    fantasy_family: Option<String>,
    monospace_family: Option<String>,
    skip_system_fonts: bool
}

impl FontProperties {
    fn from_parsed_options(parsed_options: &ParsedOptions) -> Self {
        Self {
            font_files: parsed_options.font_files.clone(),
            font_dirs: parsed_options.font_dirs.clone(),
            serif_family: parsed_options.serif_family.clone(),
            sans_serif_family: parsed_options.sans_serif_family.clone(),
            cursive_family: parsed_options.cursive_family.clone(),
            fantasy_family: parsed_options.fantasy_family.clone(),
            monospace_family: parsed_options.monospace_family.clone(),
            skip_system_fonts: parsed_options.skip_system_fonts.clone()
        }
    }
}

#[derive(NifStruct)]
#[module = "Resvg.Options"]
pub struct Options {
    width: Option<u32>,
    height: Option<u32>,
    zoom: Option<f32>,
    dpi: u32,
    background: Option<String>,
    languages: Vec<String>,
    shape_rendering: ShapeRenderingWrapper,
    text_rendering: TextRenderingWrapper,
    image_rendering: ImageRenderingWrapper,
    resources_dir: Option<String>,

    font_family: Option<String>,
    font_size: u32,
    serif_family: Option<String>,
    sans_serif_family: Option<String>,
    cursive_family: Option<String>,
    fantasy_family: Option<String>,
    monospace_family: Option<String>,
    font_files: Vec<String>,
    font_dirs: Vec<String>,
    skip_system_fonts: bool,
}

#[derive(NifStruct)]
#[module = "Resvg.Native.Node"]
struct Node {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

struct ParsedOptions<'a> {
    // TODO implements these
    // export_id: Option<String>,
    // export_area_page: bool,
    // export_area_drawing: bool,
    usvg: usvg::Options<'a>,
    fit_to: FitTo,
    background: Option<svgtypes::Color>,
    serif_family: Option<String>,
    sans_serif_family: Option<String>,
    cursive_family: Option<String>,
    fantasy_family: Option<String>,
    monospace_family: Option<String>,
    font_files: Vec<path::PathBuf>,
    font_dirs: Vec<path::PathBuf>,
    skip_system_fonts: bool,
}

#[rustler::nif]
pub fn svg_to_png<'a>(
    env: Env<'a>,
    in_svg: String,
    out_png: String,
    options: Options,
) -> NifResult<Term<'a>> {
    let input_from = InputFrom::File(path::PathBuf::from(&in_svg));

    let mut parsed_options = try_or_return_elixir_err!(parse_options(input_from, options), env);
    let font_properties = FontProperties::from_parsed_options(&parsed_options);

    let mut svg_data = try_or_return_elixir_err!(
        std::fs::read(&in_svg).map_err(|e| format!("Error loading svg file: {}", e)),
        env
    );

    if svg_data.starts_with(&[0x1f, 0x8b]) {
        svg_data = try_or_return_elixir_err!(
            usvg::decompress_svgz(&svg_data).map_err(|e| e.to_string()),
            env
        );
    };

    let svg_string = try_or_return_elixir_err!(
        std::str::from_utf8(&svg_data)
            .map_err(|_| "provided data has not an UTF-8 encoding".to_string()),
        env
    );

    let xml_opt = usvg::roxmltree::ParsingOptions {
        allow_dtd: true,
        ..Default::default()
    };

    let xml_tree = try_or_return_elixir_err!(
        usvg::roxmltree::Document::parse_with_options(svg_string, xml_opt)
            .map_err(|e| e.to_string()),
        env
    );

    // fontdb initialization is pretty expensive, so perform it only when needed.
    let has_text_nodes = xml_tree
        .descendants()
        .any(|n| n.has_tag_name(("http://www.w3.org/2000/svg", "text")));

    if has_text_nodes {
        match load_fonts(&font_properties, parsed_options.usvg.fontdb_mut()) {
            Ok(_) => (),
            Err(error) => return Ok((atoms::error(), error).encode(env))
        };
    }

    let tree = try_or_return_elixir_err!(
        usvg::Tree::from_xmltree(&xml_tree, &parsed_options.usvg).map_err(|e| e.to_string()),
        env
    );

    let img = try_or_return_elixir_err!(render_svg(&parsed_options, &tree), env);

    match img.save_png(out_png).map_err(|e| e.to_string()) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(error_msg) => return Ok((atoms::error(), error_msg).encode(env)),
    }
}

#[rustler::nif]
pub fn svg_string_to_png<'a>(
    env: Env<'a>,
    svg_string: String,
    out_png: String,
    options: Options,
) -> NifResult<Term<'a>> {
    let input_from = InputFrom::Text;

    let mut parsed_options = try_or_return_elixir_err!(parse_options(input_from, options), env);
    let font_properties = FontProperties::from_parsed_options(&parsed_options);

    let xml_opt = usvg::roxmltree::ParsingOptions {
        allow_dtd: true,
        ..Default::default()
    };

    let xml_tree = try_or_return_elixir_err!(
        usvg::roxmltree::Document::parse_with_options(&svg_string, xml_opt)
            .map_err(|e| e.to_string()),
        env
    );

    let has_text_nodes = xml_tree
        .descendants()
        .any(|n| n.has_tag_name(("http://www.w3.org/2000/svg", "text")));

    if has_text_nodes {
        match load_fonts(&font_properties, parsed_options.usvg.fontdb_mut()) {
            Ok(_) => (),
            Err(error) => return Ok((atoms::error(), error).encode(env))
        };
    }

    let tree = try_or_return_elixir_err!(
        usvg::Tree::from_xmltree(&xml_tree, &parsed_options.usvg).map_err(|e| e.to_string()),
        env
    );

    let img = try_or_return_elixir_err!(render_svg(&parsed_options, &tree), env);

    match img.save_png(out_png).map_err(|e| e.to_string()) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(error_msg) => return Ok((atoms::error(), error_msg).encode(env)),
    }
}

#[rustler::nif]
pub fn svg_string_to_png_buffer<'a>(
    env: Env<'a>,
    svg_string: String,
    options: Options,
) -> NifResult<Term<'a>> {
    let input_from = InputFrom::Text;

    let mut parsed_options = try_or_return_elixir_err!(parse_options(input_from, options), env);
    let font_properties = FontProperties::from_parsed_options(&parsed_options);

    let xml_opt = usvg::roxmltree::ParsingOptions {
        allow_dtd: true,
        ..Default::default()
    };

    let xml_tree = try_or_return_elixir_err!(
        usvg::roxmltree::Document::parse_with_options(&svg_string, xml_opt)
            .map_err(|e| e.to_string()),
        env
    );

    let has_text_nodes = xml_tree
        .descendants()
        .any(|n| n.has_tag_name(("http://www.w3.org/2000/svg", "text")));

    if has_text_nodes {
        match load_fonts(&font_properties, parsed_options.usvg.fontdb_mut()) {
            Ok(_) => (),
            Err(error) => return Ok((atoms::error(), error).encode(env))
        };
    }

    let tree = try_or_return_elixir_err!(
        usvg::Tree::from_xmltree(&xml_tree, &parsed_options.usvg).map_err(|e| e.to_string()),
        env
    );

    let img = try_or_return_elixir_err!(render_svg(&parsed_options, &tree), env);

    match img.encode_png().map_err(|e| e.to_string()) {
        Ok(buf) => Ok((atoms::ok(), buf).encode(env)),
        Err(error_msg) => return Ok((atoms::error(), error_msg).encode(env)),
    }
}

#[rustler::nif]
pub fn list_fonts<'a>(env: Env<'a>, options: Options) -> NifResult<Term<'a>> {
    let mut parsed_options = match parse_options(InputFrom::Empty, options) {
        Ok(parsed_options) => parsed_options,
        Err(error_msg) => return Ok((atoms::error(), error_msg).encode(env)),
    };

    let font_properties = FontProperties::from_parsed_options(&parsed_options);
    let fontdb = parsed_options.usvg.fontdb_mut();

    match load_fonts(&font_properties, fontdb) {
        Ok(_) => (),
        Err(error) => return Ok((atoms::error(), error).encode(env))
    };

    let font_info_strings: Vec<String> = fontdb
        .faces()
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

    Ok((atoms::ok(), font_info_strings).encode(env))
}

#[rustler::nif]
pub fn query_all<'a>(env: Env<'a>, in_svg: String, options: Options) -> NifResult<Term<'a>> {
    let input_from = InputFrom::File(path::PathBuf::from(&in_svg));

    let mut parsed_options = try_or_return_elixir_err!(parse_options(input_from, options), env);
    let font_properties = FontProperties::from_parsed_options(&parsed_options);

    let mut svg_data = try_or_return_elixir_err!(
        std::fs::read(&in_svg).map_err(|e| format!("Error loading svg file: {}", e)),
        env
    );

    if svg_data.starts_with(&[0x1f, 0x8b]) {
        svg_data = try_or_return_elixir_err!(
            usvg::decompress_svgz(&svg_data).map_err(|e| e.to_string()),
            env
        );
    };

    let svg_string = try_or_return_elixir_err!(
        std::str::from_utf8(&svg_data)
            .map_err(|_| "provided data has not an UTF-8 encoding".to_string()),
        env
    );
    
    let xml_opt = usvg::roxmltree::ParsingOptions {
        allow_dtd: true,
        ..Default::default()
    };

    let xml_tree = try_or_return_elixir_err!(
        usvg::roxmltree::Document::parse_with_options(svg_string, xml_opt)
            .map_err(|e| e.to_string()),
        env
    );

    // fontdb initialization is pretty expensive, so perform it only when needed.
    let has_text_nodes = xml_tree
        .descendants()
        .any(|n| n.has_tag_name(("http://www.w3.org/2000/svg", "text")));

    if has_text_nodes {
        match load_fonts(&font_properties, parsed_options.usvg.fontdb_mut()) {
            Ok(_) => (),
            Err(error) => return Ok((atoms::error(), error).encode(env))
        };
    }

    let tree = try_or_return_elixir_err!(
        usvg::Tree::from_xmltree(&xml_tree, &parsed_options.usvg).map_err(|e| e.to_string()),
        env
    );

    fn round_len(v: f32) -> f32 {
        (v * 1000.0).round() / 1000.0
    }

    let result: Vec<Node> = tree
        .root()
        .children()
        .into_iter()
        .filter_map(|node| {
            if node.id().is_empty() {
                None
            } else {
                let bbox = node.abs_stroke_bounding_box();
    
                let node = Node {
                    id: node.id().to_string(),
                    x: round_len(bbox.x()),
                    y: round_len(bbox.y()),
                    width: round_len(bbox.width()),
                    height: round_len(bbox.height()),
                };

                Some(node)
            }
        })
        .collect();

    Ok(result.encode(env))
}

fn parse_options<'a>(in_svg: InputFrom, options: Options) -> Result<ParsedOptions<'a>, String> {
    let mut fit_to = FitTo::Original;
    let mut default_size = usvg::Size::from_wh(100.0, 100.0).unwrap();
    if let (Some(w), Some(h)) = (options.width, options.height) {
        default_size = usvg::Size::from_wh(w as f32, h as f32).unwrap();
        fit_to = FitTo::Size(w, h);
    } else if let Some(w) = options.width {
        default_size = usvg::Size::from_wh(w as f32, 100.0).unwrap();
        fit_to = FitTo::Width(w);
    } else if let Some(h) = options.height {
        default_size = usvg::Size::from_wh(100.0, h as f32).unwrap();
        fit_to = FitTo::Height(h);
    } else if let Some(z) = options.zoom {
        fit_to = FitTo::Zoom(z);
    }

    let resources_dir = match options.resources_dir {
        Some(v) => Some(path::PathBuf::from(v)),
        None => match in_svg {
            InputFrom::File(ref path) => std::fs::canonicalize(&path)
                .ok()
                .and_then(|p| p.parent().map(|p| p.to_path_buf())),

            InputFrom::Text | InputFrom::Empty => {
                return Err(
                    "Make sure to set resources_dir when you are not passing a svg path"
                        .to_string(),
                )
            }
        },
    };

    let usvg_options = usvg::Options {
        resources_dir,
        dpi: options.dpi as f32,
        font_family: options
            .font_family
            .clone()
            .take()
            .unwrap_or_else(|| "Times New Roman".to_string()),
        font_size: options.font_size as f32,
        languages: options.languages,
        shape_rendering: options.shape_rendering.get(),
        text_rendering: options.text_rendering.get(),
        image_rendering: options.image_rendering.get(),
        default_size: default_size,
        image_href_resolver: usvg::ImageHrefResolver::default(),
        font_resolver: usvg::FontResolver::default(),
        fontdb: Arc::new(fontdb::Database::new()),
        style_sheet: None

    };

    let background = match options.background {
        Some(color_str) => match color_str.parse::<svgtypes::Color>() {
            Ok(color) => Some(color),
            Err(error) => return Err(format!("Error background: {}", error)),
        },
        None => None,
    };

    let font_files = options
        .font_files
        .iter()
        .map(|s| path::PathBuf::from(s))
        .collect();

    let font_dirs = options
        .font_dirs
        .iter()
        .map(|s| path::PathBuf::from(s))
        .collect();

    Ok(ParsedOptions {
        usvg: usvg_options,
        fit_to,
        background,
        serif_family: options.serif_family,
        sans_serif_family: options.sans_serif_family,
        cursive_family: options.cursive_family,
        fantasy_family: options.fantasy_family,
        monospace_family: options.monospace_family,
        font_files,
        font_dirs,
        skip_system_fonts: options.skip_system_fonts,
    })
}

fn load_fonts(font_properties: &FontProperties, fontdb: &mut fontdb::Database)
        -> Result<(), String> {
    if !font_properties.skip_system_fonts {
        fontdb.load_system_fonts();
    }

    for path in &font_properties.font_files {
        fontdb
            .load_font_file(path)
            .map_err(|e| format!("Error loading font file: {}", e))?;
    }

    for path in &font_properties.font_dirs {
        fontdb.load_fonts_dir(path);
    }

    fontdb.set_serif_family(font_properties.serif_family.as_deref().unwrap_or("Times New Roman"));
    fontdb.set_sans_serif_family(font_properties.sans_serif_family.as_deref().unwrap_or("Arial"));
    fontdb.set_cursive_family(font_properties.cursive_family.as_deref().unwrap_or("Comic Sans MS"));
    fontdb.set_fantasy_family(font_properties.fantasy_family.as_deref().unwrap_or("Impact"));
    fontdb.set_monospace_family(font_properties.monospace_family.as_deref().unwrap_or("Courier New"));

    Ok(())
}

impl<'a> Decoder<'a> for ShapeRenderingWrapper {
    fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
        let atom = term.atom_to_string()?;
        let value = match atom.as_str() {
            "optimize_speed" => ShapeRendering::OptimizeSpeed,
            "crisp_edges" => ShapeRendering::CrispEdges,
            "geometric_precision" => ShapeRendering::GeometricPrecision,
            _ => return Err(rustler::Error::BadArg),
        };
        Ok(Self { value })
    }
}

impl Encoder for ShapeRenderingWrapper {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        let atom_str = match self.value {
            ShapeRendering::OptimizeSpeed => "optimize_speed",
            ShapeRendering::CrispEdges => "crisp_edges",
            ShapeRendering::GeometricPrecision => "geometric_precision",
        };
        atom_str.encode(env)
    }
}

impl ShapeRenderingWrapper {
    fn get(&self) -> ShapeRendering {
        self.value
    }
}

impl<'a> Decoder<'a> for TextRenderingWrapper {
    fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
        let atom = term.atom_to_string()?;
        let value = match atom.as_str() {
            "optimize_speed" => TextRendering::OptimizeSpeed,
            "optimize_legibility" => TextRendering::OptimizeLegibility,
            "geometric_precision" => TextRendering::GeometricPrecision,
            _ => return Err(rustler::Error::BadArg),
        };
        Ok(Self { value })
    }
}

impl Encoder for TextRenderingWrapper {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        let atom_str = match self.value {
            TextRendering::OptimizeSpeed => "optimize_speed",
            TextRendering::OptimizeLegibility => "optimize_legibility",
            TextRendering::GeometricPrecision => "geometric_precision",
        };
        atom_str.encode(env)
    }
}

impl TextRenderingWrapper {
    fn get(&self) -> TextRendering {
        self.value
    }
}

impl<'a> Decoder<'a> for ImageRenderingWrapper {
    fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
        let atom = term.atom_to_string()?;
        let value = match atom.as_str() {
            "optimize_quality" => ImageRendering::OptimizeQuality,
            "optimize_speed" => ImageRendering::OptimizeSpeed,
            _ => return Err(rustler::Error::BadArg),
        };
        Ok(Self { value })
    }
}

impl Encoder for ImageRenderingWrapper {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        let atom_str = match self.value {
            ImageRendering::OptimizeQuality => "optimize_quality",
            ImageRendering::OptimizeSpeed => "optimize_speed",
        };
        atom_str.encode(env)
    }
}

impl ImageRenderingWrapper {
    fn get(&self) -> ImageRendering {
        self.value
    }
}

fn render_svg(
    parsed_options: &ParsedOptions,
    tree: &usvg::Tree,
) -> Result<tiny_skia::Pixmap, String> {
    let img = {
        let size = parsed_options
            .fit_to
            .fit_to_size(tree.size().to_int_size())
            .ok_or_else(|| "target size is zero".to_string())?;

        // Unwrap is safe, because `size` is already valid.
        let mut pixmap = tiny_skia::Pixmap::new(size.width(), size.height()).unwrap();

        if let Some(background) = parsed_options.background {
            pixmap.fill(svg_to_skia_color(background));
        }

        let transform = parsed_options
            .fit_to
            .fit_to_transform(tree.size().to_int_size());

        resvg::render(tree, transform, &mut pixmap.as_mut());

        pixmap
    };

    Ok(img)
}

fn svg_to_skia_color(color: svgtypes::Color) -> tiny_skia::Color {
    tiny_skia::Color::from_rgba8(color.red, color.green, color.blue, color.alpha)
}

rustler::init!(
    "Elixir.Resvg.Native",
    [
        svg_to_png,
        svg_string_to_png,
        svg_string_to_png_buffer,
        list_fonts,
        query_all
    ]
);
