#include <banana/apply.hh>

#include <carrot/apply.hh>
#include <durian/apply.hh>

namespace banana {

int apply(int x) {
    return carrot::apply(x) * durian::apply(x);
}

} // namespace banana
