# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import docutils.nodes, os, logging, re, sys
from docutils import nodes
from docutils.parsers.rst import roles
from packaging.version import Version
from sphinx.application import Sphinx
from sphinx.transforms.post_transforms import SphinxTransform


sys.path.insert(0, os.path.abspath("../.."))
import graphistry


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


# -- Project information -----------------------------------------------------

project = "Graphistry CLI"
copyright = "2024, Graphistry, Inc."
author = "Graphistry, Inc."

html_title = "Graphistry Administration Documentation"
html_short_title = "Graphistry Admin"
html_logo = 'static/graphistry_banner_transparent_colored.png'
html_favicon = 'static/favicon.ico'

# The full version, including alpha/beta/rc tags
version = str(Version(graphistry.__version__))
release = version

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'myst_parser',
    'nbsphinx',
    "sphinx.ext.autodoc",
    #'sphinx.ext.autosummary',
    'sphinx.ext.intersphinx',
    "sphinx.ext.ifconfig",
    #"sphinx_autodoc_typehints",
    "sphinx_copybutton",
]

myst_url_schemes = ["http", "https", "mailto", "ftp", "file"]
myst_heading_anchors = 3  # Allow md files to have links with extension .md in the path

#myst_enable_extensions = ["linkify", "substitution"]
myst_enable_extensions = ["linkify"]
myst_commonmark_only = False  # Use CommonMark only
myst_heading_anchors_auto_id_prefix = False  # Disable auto ID prefix for headings

# TODO guarantee most notebooks are executable (=> maintained)
# and switch to opt'ing out the few that are hard, e.g., DB deps
nbsphinx_execute = 'never'
nbsphinx_allow_errors = False  # Allow errors in notebooks

autodoc_typehints = "description"
always_document_param_types = True
typehints_document_rtype = True

#suppress_warnings = [
#    'nbsphinx.localfile',  # Suppresses local file warnings in notebooks
#]

nitpick_ignore = []

#set_type_checking_flag = True

# typehints_fully_qualified=True
always_document_param_types = True
typehints_document_rtype = True

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
# source_suffix = ['.rst', '.md']
# source_suffix = ['.rst', '.ipynb']
source_suffix = {
     '.md': 'myst',
     '.txt': 'markdown',
    '.rst': 'restructuredtext',
    #'.ipynb': 'nbsphinx',
}
# The master toctree document.
root_doc = "index"

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = [

    '_build',
     '**/_build/**',
    'doctrees',
    '**/doctrees/**',
    '**/*.txt',

]

pygments_style = "sphinx"
todo_include_todos = False

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
#html_theme = "sphinx_rtd_theme"
html_theme = "sphinx_book_theme"


html_theme_options = {
    "repository_url": "https://github.com/graphistry/graphistry-cli",
    "use_repository_button": True,

    # Optional top horizontal navigation bar
    #"navbar_start": ["navbar-start.html"],
    #"navbar_center": ["navbar-center.html"],
    #"navbar_end": ["navbar-end.html"],
    
    "logo": {
        #"link": "https://www.graphistry.com/get-started",
        #"text": "Graphistry, Inc.",
        "alt_text": "Graphistry, Inc."
    }
}


# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['static']  # '_static'
# html_css_files = ['graphistry.css']

html_show_sphinx = False

htmlhelp_basename = "Graphistry-admin-doc"


# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
    'preamble': r'''

        \usepackage{svg}   % Enables SVG handling via Inkscape

        \RequirePackage{etex}         % Ensure extended TeX capacities
        \usepackage[utf8]{inputenc}   % Enable UTF-8 support
        \usepackage[T1]{fontenc}      % Use T1 font encoding for better character support
        \usepackage{lmodern}          % Load Latin Modern fonts for better quality
        \usepackage{amsmath}           % For advanced math formatting
        \usepackage{amsfonts}          % For math fonts
        \usepackage{amssymb}           % For additional math symbols
        \usepackage{graphicx}          % For including images
        \usepackage{hyperref}          % For hyperlinks
        \usepackage{textcomp}          % For additional text symbols
        \usepackage{breakurl}          % Allows line breaks in URLs
        \usepackage{listings}          % For code listings
        \usepackage{float}             % Improved control of floating objects
        \usepackage{microtype}         % Improves text appearance with microtypography
        \usepackage{lipsum}            % For generating dummy text (if needed)


        % Increase capacity limits
        \setcounter{totalnumber}{200}   % Maximum floats
        \setcounter{dbltopnumber}{200}   % Double float maximum
        \setcounter{secnumdepth}{3}      % Section numbering depth
        \setcounter{tocdepth}{3}          % Table of contents depth
        
        % Increase dimensions and allocations
        \usepackage{morefloats}          % Allows for more floats
        \setlength{\emergencystretch}{3em} % Help with overfull hboxes
        \setlength{\maxdepth}{100pt}       % Sets a high limit for max depth (if applicable)

        % Allocate more memory for TeX
        \usepackage{etex}                % Use eTeX for more memory
        %\reserveinserts{200}             % Reserve more inserts
        \setcounter{totalnumber}{200}    % Ensure maximum floats are increased


        % Declare Unicode characters
        \DeclareUnicodeCharacter{1F389}{\textbf{(party popper)}}
        \DeclareUnicodeCharacter{1F3C6}{\textbf{(trophy)}}
        \DeclareUnicodeCharacter{1F44D}{\textbf{(thumbs up)}}
        \DeclareUnicodeCharacter{1F4AA}{\textbf{Strong}}  % Muscle emoji
        \DeclareUnicodeCharacter{1F4B0}{\textbf{Money Bag}} % Money bag emoji (text representation)
        \DeclareUnicodeCharacter{1F525}{\textbf{(fire)}}
        \DeclareUnicodeCharacter{1F600}{\textbf{(grinning)}}
        \DeclareUnicodeCharacter{1F609}{\textbf{(winking)}}
        \DeclareUnicodeCharacter{1F614}{\textbf{(pensive)}}
        \DeclareUnicodeCharacter{1F680}{\textbf{(rocket)}}
        \DeclareUnicodeCharacter{2501}{\textbf{━}}         % Heavy horizontal line
        \DeclareUnicodeCharacter{2588}{\textbf{█}}         % Full block character
        \DeclareUnicodeCharacter{258A}{\textbf{▊}}         % Center right block character
        \DeclareUnicodeCharacter{258B}{\textbf{▉}}         % Right block character
        \DeclareUnicodeCharacter{258C}{\textbf{▌}}         % Center block character
        \DeclareUnicodeCharacter{258D}{\textbf{▍}}         % Center left block character
        \DeclareUnicodeCharacter{258E}{\textbf{▎}}         % Left third block character
        \DeclareUnicodeCharacter{258F}{\textbf{▏}}         % Right block character
        \DeclareUnicodeCharacter{2728}{\textbf{(sparkles)}}
        \DeclareUnicodeCharacter{2764}{\textbf{(heart)}}
        \DeclareUnicodeCharacter{2B50}{\textbf{(star)}}

    ''',
}

# Use pdflatex as the LaTeX engine
latex_engine = 'pdflatex'

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (
        root_doc,
        "Graphistry.tex",
        u"Graphistry Admin Documentation",
        u"Graphistry, Inc.",
        "manual",
    ),
]

# The name of an image file (relative to this directory) to place at the top of
# the title page.
# latex_logo = None

# For "manual" documents, if this is true, then toplevel headings are parts,
# not chapters.
# latex_use_parts = False

# If true, show page references after internal links.
# latex_show_pagerefs = False

# If true, show URL addresses after external links.
# latex_show_urls = False

# Documents to append as an appendix to all manuals.
# latex_appendices = []

# If false, no module index is generated.
latex_domain_indices = False


# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [(root_doc, "graphistry-admin-docs", u"Graphistry Admin Documentation", [author], 1)]

# If true, show URL addresses after external links.
# man_show_urls = False


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (
        root_doc,
        "Graphistry",
        u"Praphistry Admin Documentation",
        author,
        "Graphistry",
        "Admin documents for Graphistry.",
        "Miscellaneous",
    ),
]

# Documents to append as an appendix to all manuals.
# texinfo_appendices = []

# If false, no module index is generated.
texinfo_domain_indices = False

# How to display URL addresses: 'footnote', 'no', or 'inline'.
# texinfo_show_urls = 'footnote'

# If true, do not generate a @detailmenu in the "Top" node's menu.
# texinfo_no_detailmenu = False


# -- Options for Epub output ----------------------------------------------

# Bibliographic Dublin Core info.
epub_title = project
epub_author = author
epub_publisher = author
epub_copyright = copyright

# The basename for the epub file. It defaults to the project name.
# epub_basename = project

# The HTML theme for the epub output. Since the default themes are not optimized
# for small screen space, using the same theme for HTML and epub output is
# usually not wise. This defaults to 'epub', a theme designed to save visual
# space.
# epub_theme = 'epub'

# The language of the text. It defaults to the language option
# or 'en' if the language is not set.
# epub_language = ''

# The scheme of the identifier. Typical schemes are ISBN or URL.
# epub_scheme = ''

# The unique identifier of the text. This can be a ISBN number
# or the project homepage.
# epub_identifier = ''

# A unique identification for the text.
# epub_uid = ''

# A tuple containing the cover image and cover page html template filenames.
# epub_cover = ()

# A sequence of (type, uri, title) tuples for the guide element of content.opf.
# epub_guide = ()

# HTML files that should be inserted before the pages created by sphinx.
# The format is a list of tuples containing the path and title.
# epub_pre_files = []

# HTML files shat should be inserted after the pages created by sphinx.
# The format is a list of tuples containing the path and title.
# epub_post_files = []

# A list of files that should not be packed into the epub file.
epub_exclude_files = ["search.html"]

# The depth of the table of contents in toc.ncx.
# epub_tocdepth = 3

# Allow duplicate toc entries.
# epub_tocdup = True

# Choose between 'default' and 'includehidden'.
# epub_tocscope = 'default'

# Fix unsupported image types using the Pillow.
# epub_fix_images = False

# Scale large images.
# epub_max_image_width = 0

# How to display URL addresses: 'footnote', 'no', or 'inline'.
# epub_show_urls = 'inline'

# If false, no index is generated.
# epub_use_index = True


# Example configuration for intersphinx: refer to the Python standard library.
# intersphinx_mapping = {'https://docs.python.org/': None}



# -- Custom Preprocessor Configuration ---------------------------------------

def replace_iframe_src(app, doctree, docname):
    """
    Replace relative iframe src paths with absolute URLs in HTML content.
    Specifically targets iframe tags with src attributes starting with /graph/.
    """
    # Define a flexible regex pattern to match <iframe> tags with src="/graph/..."
    # This pattern accounts for single or double quotes and any additional attributes
    pattern = re.compile(
        r'(<iframe[^>]*src\s*=\s*[\'"])(/graph/[^\'"]+)([\'"][^>]*>)', 
        re.IGNORECASE | re.DOTALL
    )

    # Flag to check if any replacement occurred in this document
    replacement_occurred = False

    # Iterate over all nodes in the doctree
    for node in doctree.traverse():
        # Process only nodes that can contain text
        if isinstance(node, (docutils.nodes.raw, docutils.nodes.literal_block, docutils.nodes.paragraph, docutils.nodes.Text)):
            # Determine the content based on node type
            if isinstance(node, docutils.nodes.raw):
                node_format = getattr(node, 'format', '').lower()
                if node_format != 'html':
                    continue  # Skip non-HTML raw nodes
                original_content = node.rawsource
                # Perform the regex substitution
                updated_content, count = pattern.subn(r'\1https://hub.graphistry.com\2\3', original_content)
                if count > 0:
                    node.rawsource = updated_content
                    logger.info(f"Updated {count} iframe src in document: {docname}")
                    replacement_occurred = True
            elif isinstance(node, docutils.nodes.literal_block) or isinstance(node, docutils.nodes.paragraph):
                original_content = node.astext()
                # Perform the regex substitution
                updated_content, count = pattern.subn(r'\1https://hub.graphistry.com\2\3', original_content)
                if count > 0:
                    # Replace the node's text with updated content
                    new_nodes = docutils.nodes.inline(text=updated_content)
                    node.parent.replace(node, new_nodes)
                    logger.info(f"Updated {count} iframe src in document: {docname}")
                    replacement_occurred = True
            elif isinstance(node, docutils.nodes.Text):
                original_text = node.astext()
                # Perform the regex substitution
                updated_text, count = pattern.subn(r'\1https://hub.graphistry.com\2\3', original_text)
                if count > 0:
                    # Replace the text node with updated text
                    new_text_node = docutils.nodes.Text(updated_text)
                    node.parent.replace(node, new_text_node)
                    logger.info(f"Updated {count} iframe src in document: {docname}")
                    replacement_occurred = True

    if not replacement_occurred:
        logger.debug(f"No iframe src replacements made in document: {docname}")


def ignore_svg_images_for_latex(app, doctree, docname):
    """Remove SVG images from the LaTeX build."""
    if app.builder.name == 'latex':
        for node in doctree.traverse(nodes.image):
            if node['uri'].endswith('.svg'):
                node.parent.remove(node)

def remove_external_images_for_latex(app, doctree, fromdocname):
    """Remove external images and handle external links in LaTeX and EPUB builds."""
    if app.builder.name in ['latex', 'epub']:  # Extend to all builds if needed
        logger.info(f"Processing doctree for output: {fromdocname}")
        
        # Handle problematic external images
        for node in doctree.traverse(nodes.image):
            image_uri = node['uri']
            logger.debug(f"Processing image URI: {image_uri}")
            if "://" in image_uri:  # Identify external images
                logger.debug(f"Detected external image URI: {image_uri}")
                try:
                    if node.parent:
                        # Preserve node attributes such as "classes"
                        parent = node.parent
                        classes = node.get('classes', [])
                        logger.debug(f"Preserving classes attribute: {classes}")
                        parent.remove(node)  # Remove external image node
                        logger.info(f"Successfully removed external image: {image_uri}")
                    else:
                        logger.error(f"No parent found for image: {image_uri}")
                except Exception as e:
                    logger.error(f"Failed to remove external image: {image_uri} with error {str(e)}")
            else:
                logger.debug(f"Retained local image: {image_uri}")
        
        # Handle problematic external links
        for node in doctree.traverse(nodes.reference):
            if node.get('refuri', '').startswith('http'):
                logger.debug(f"Handling external link: {node['refuri']}")
                if node['refuri'].endswith('.com'):
                    logger.warning(f"Found problematic URL ending in .com: {node['refuri']}")
                    # Preserve "classes" attribute and replace link
                    classes = node.get('classes', [])
                    logger.debug(f"Preserving classes attribute: {classes}")
                    inline_node = nodes.inline('', f"{node['refuri']} (external link)", classes=classes)
                    node.replace_self(inline_node)
                else:
                    # Keep non-problematic URLs
                    inline_node = nodes.inline('', node['refuri'], classes=node.get('classes', []))
                    node.replace_self(inline_node)

        logger.info("Finished processing images and links.")

def assert_external_images_removed(app, doctree, fromdocname):
    """Assert that external images have been removed."""
    if app.builder.name in ['html']:  # Extend to all builds if needed
        return

    for node in doctree.traverse(nodes.image):
        image_uri = node['uri']
        if "://" in image_uri:
            logger.error(f"Assertion failed: external image was not removed: {image_uri}")
        assert "://" not in image_uri, f"Failed to remove external image: {image_uri}"





# Step 1: Log include directives to ensure paths are correct
def validate_includes(app, docname, source):
    includes_not_found = []
    content = source[0]
    for line in content.splitlines():
        if ".. include::" in line:
            included_file = line.split("include::")[1].strip()
            abs_path = os.path.join(app.confdir, included_file)
            if not os.path.isfile(abs_path):
                includes_not_found.append((included_file, abs_path))
    if includes_not_found:
        logger.warning(f"{docname}: Missing includes: {includes_not_found}")

# Step 2: Log conversion of '.md' to '.html' links in documents



def convert_md_links(app, docname, source):
    content = source[0]
    converted_links = []
    skipped_links = []  # Track links that were skipped or didn't convert correctly

    for word in content.split():
        if ".md" in word:
            original_link = word
            new_link = word.replace(".md", ".html")
            
            # Check if the converted file exists
            abs_path = os.path.abspath(os.path.join(app.confdir, new_link))
            if not os.path.isfile(abs_path):
                skipped_links.append((original_link, new_link, abs_path))
            else:
                # Convert the link if the target file exists
                content = content.replace(word, new_link)
                converted_links.append((original_link, new_link, abs_path))
    
    # Apply the modified content back to the source
    source[0] = content

    # Log both converted and skipped links for debugging
    if converted_links:
        logger.info(f"{docname}: Successfully converted .md links to .html: {converted_links}")
    if skipped_links:
        logger.warning(f"{docname}: Skipped links (target missing): {skipped_links}")



def log_missing_references(app, env, docnames=None):
    if not docnames:
        docnames = env.found_docs

    unresolved_refs = {}
    for docname in docnames:
        doctree = env.get_doctree(docname)
        # Only traverse 'reference' nodes
        for ref_node in doctree.traverse(nodes.reference):
            refuri = ref_node.get("refuri")
            if refuri and not refuri.startswith(("http:", "https:")):
                try:
                    resolved = env.domains["std"].resolve_xref(
                        env, app.builder, docname, "ref", refuri, ref_node, None
                    )
                    if not resolved:
                        unresolved_refs.setdefault(docname, []).append(refuri)
                except Exception as e:
                    logger.warning(f"{docname}: Error resolving {refuri} - {str(e)}")
    if unresolved_refs:
        logger.warning(f"Unresolved references: {unresolved_refs}")



def log_unresolved_references(app, env, docnames=None):
    if not docnames:
        docnames = env.found_docs

    unresolved_refs = {}
    for docname in docnames:
        doctree = env.get_doctree(docname)
        for ref_node in doctree.traverse(nodes.reference):
            refuri = ref_node.get("refuri")
            if refuri and not refuri.startswith(("http:", "https:")):
                resolved = env.domains["std"].resolve_xref(env, app.builder, docname, "ref", refuri, ref_node, None)
                if not resolved:
                    unresolved_refs.setdefault(docname, []).append(refuri)
                    print(f"Unresolved reference in {docname}: {refuri}")

    if unresolved_refs:
        print(f"Unresolved references: {unresolved_refs}")


def check_paths(app):
    readme_path = os.path.join(app.confdir, 'README.md')
    logger.info(f"Checking README.md path: {readme_path} - Exists: {os.path.isfile(readme_path)}")

def check_readme_path(app):
    readme_path = os.path.join(app.srcdir, 'README.md')
    if not os.path.isfile(readme_path):
        logger.error(f"README.md path not found at: {readme_path}")
    else:
        logger.info(f"README.md found at: {readme_path}")

def setup(app: Sphinx):
    app.connect("builder-inited", check_readme_path)
    app.connect("builder-inited", check_paths)
    app.connect("source-read", validate_includes)
    app.connect("source-read", convert_md_links)
    app.connect("env-updated", log_missing_references)
    app.connect("env-updated", log_unresolved_references)


    # Configure MyST to handle .md files in Sphinx
    logger.info("Setup completed with enhanced logging and link validation.")

    app.connect("doctree-resolved", ignore_svg_images_for_latex)
    app.connect("doctree-resolved", remove_external_images_for_latex)
    app.connect('doctree-resolved', replace_iframe_src)
    app.connect("doctree-resolved", assert_external_images_removed)
    app.add_css_file('graphistry.css', priority=900)