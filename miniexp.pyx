	
cdef extern from "libdjvu/miniexp.h":
	cdef extern struct cexp_s "miniexp_s"
	ctypedef cexp_s* cexp_t "miniexp_t"

	int cexp_is_int "miniexp_numberp"(cexp_t sexp)
	int cexp_to_int "miniexp_to_int"(cexp_t sexp)
	cexp_t int_to_cexp "miniexp_number"(int n)
	
	int cexp_is_symbol "miniexp_symbolp"(cexp_t sexp)
	char* cexp_to_symbol "miniexp_to_name"(cexp_t sexp)
	cexp_t symbol_to_cexp "miniexp_symbol"(char* name)

	cexp_t cexp_nil "miniexp_nil"
	cexp_t cexp_dummy "miniexp_dummy"
	int cexp_is_list "miniexp_listp"(cexp_t exp)
	int cexp_is_nonempty_list "miniexp_consp"(cexp_t exp)
	int cexp_length "miniexp_length"(cexp_t exp)
	cexp_t cexp_head "miniexp_car"(cexp_t exp)
	cexp_t cexp_tail "miniexp_cdr"(cexp_t exp)
	cexp_t cexp_nth "miniexp_nth"(int n, cexp_t exp)
	cexp_t pair_to_cexp "miniexp_cons"(cexp_t head, cexp_t tail)
	cexp_t cexp_replace_head "miniexp_rplaca"(cexp_t exp, cexp_t new_head)
	cexp_t cexp_replace_tail "miniexp_rplacd"(cexp_t exp, cexp_t new_tail)
	cexp_t cexp_reverse_list "miniexp_reverse"(cexp_t exp)

def Expression(value):
	if isinstance(value, (int, long)):
		return IntExpression(value)
	elif isinstance(value, str):
		return SymbolExpression(value)
	else:
		try:
			iter(value)
		except TypeError:
			raise
		else:
			return ListExpression(value)

cdef class _Expression:
	cdef cexp_t cexp
	
	def __repr__(self):
		return 'Expression(%r)' % (self.get_value(),)

cdef class IntExpression(_Expression):

	def __new__(self, value):
		if not isinstance(value, (int, long)):
			raise TypeError
		if -1 << 29 <= value <= 1 << 29:
			self.cexp = int_to_cexp(value)
		else:
			raise ValueError

	def get_value(self):
		return cexp_to_int(self.cexp)

cdef class SymbolExpression(_Expression):

	def __new__(self, value):
		if isinstance(value, str):
			self.cexp = symbol_to_cexp(value)
		else:
			raise TypeError

	def get_value(self):
		return cexp_to_symbol(self.cexp)

cdef cexp_t _py2c(_Expression pyexp):
	return pyexp.cexp

cdef void _py_set_value(_Expression pyexp, cexp_t cexp):
	pyexp.cexp = cexp

cdef _Expression _c2py(cexp_t cexp):
	if cexp_is_int(cexp):
		result = IntExpression(0)
	elif cexp_is_symbol(cexp):
		result = SymbolExpression('')
	elif cexp_is_list(cexp):
		result = ListExpression(())
	else:
		raise TypeError
	_py_set_value(result, cexp)
	return result

cdef class ListExpression(_Expression):

	def __new__(self, items):
		self.cexp = cexp_nil
		for item in items:
			self.cexp = pair_to_cexp(_py2c(Expression(item)), self.cexp)
		self.cexp = cexp_reverse_list(self.cexp)

	def get_value(self):
		cdef cexp_t current
		current = self.cexp
		result = []
		while current != cexp_nil:
			result.append(_c2py(cexp_head(current)).get_value())
			current = cexp_tail(current)
		return tuple(result)

# vim:ts=4 sw=4 noet
