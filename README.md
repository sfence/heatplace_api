Heatplace API
==============

Heatplace api for minetest.
Include support for fireplaces.

License
-------

See LICENSE file for details.

MIT for source code

Testing
-------

Copy or link `test_api` to `test_api` directory in main mod directory.
`test_api` can be found on `https://github.com/sfence/test_api`.

Run python file `tb_*.py`.

Adding fuels
------------

Temp of flame is equal to: `burn_energy/((smoke_amount + oxygen_need)*heat_capacity) `
