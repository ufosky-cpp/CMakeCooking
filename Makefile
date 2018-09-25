THIS_MAKEFILE:=$(shell dirname $(realpath $lastword $(MAKEFILE_LIST)))
PANTRY=$(THIS_MAKEFILE)/pantry
VERBOSITY?=info

all: doc test

doc:
	dune build @doc

test: test_unit test_model test_integration

test_unit:
	dune runtest

test_model:
	dune exec cooking-test-model -- --verbosity=$(VERBOSITY)

test_integration:
	dune exec cooking-test-integration -- --verbosity=$(VERBOSITY) $(PANTRY)

clean:
	dune clean

.PHONY: clean doc test_integration test_model test_unit
