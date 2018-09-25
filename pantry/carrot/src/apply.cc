#include <carrot/apply.hh>

#include <durian/apply.hh>
#include <egg/apply.hh>

namespace carrot {

int apply(int x) {
    return durian::apply(x) - egg::apply(x);
}

} // namespace carrot
