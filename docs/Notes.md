## Bits Runner (under development)

Development relase of the Bits Runner OS created with the Bits Runner Code language.

Changelist:
- [1.0.0-dev-15](https://github.com/rafalgrodzinski/bits-runner/pull/46)
  - Timer-based process switching
  - Sleep system call
- [1.0.0-dev-14](https://github.com/rafalgrodzinski/bits-runner/pull/43)
  - Builds with O2 optimizaion for much smaller sizes
  - Corrected memory detection
  - Initial kernel stack is reused for the first process
  - Kernel page directory and tables are now dynamically allocated in kernel's heap
  - Sourcecode improvements for the latest version of brb
  - Refactored dispatch and memory management
  - Allocate pages for kernel and user allocations