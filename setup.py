#! /usr/bin/env python

import os, sys
from distutils.core import setup

setup (
        name = "SVGMath",
        version = "0.3.3",
        url = "http://svgmath.sourceforge.net/",
        description = "MathML-to-SVG converter",
        long_description = """Converter from MathML (Mathematical Markup Language) to SVG (Scalable Vector Graphics).""",

        author = "Nikolai Grigoriev",
        author_email = "svgmath@grigoriev.ru",
        maintainer = "Nikolai Grigoriev",
        maintainer_email = "svgmath@grigoriev.ru",

        packages = [ "svgmath", "svgmath.fonts", "svgmath.tools" ],
        package_data = { "svgmath.fonts": ["default.glyphs"] }
)

