include $(top_srcdir)/rules/rel.mk

OTP_RELEASES = sipua sipb2bua

AM_ERL_FLAGS = -pa $(top_builddir)/sipua/ebin -pa	\
$(top_builddir)/sipb2bua/ebin

run:
	$(ERL) $(AM_ERL_FLAGS) $(ERL_FLAGS) $(AM_ERLCFLAGS) $(ERLCFLAGS)
# -s systools make_tar sipb2bua -s init exit

run-sipb2bua:
	$(ERL) $(AM_ERL_FLAGS) $(ERL_FLAGS) -name eryate -boot sipb2bua -sasl sasl_error_logger '{file,"sasl.log"}' -mnesia dir '"/var/tmp/mnesia/eryate"' -yxa_config sipb2bua.config -s appmon start
