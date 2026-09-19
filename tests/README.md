# tests/

Unit tests for the model layer (flux maths, damage resolution, save
migrations, market pricing). The framework is [gdUnit4](https://github.com/MikeSchulze/gdUnit4),
installed as an addon in milestone M2 when the first pure-logic module lands.
Tests target `src/**` code that has no scene dependency.
