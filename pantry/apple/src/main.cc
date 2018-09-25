#include <iostream>

#include <banana/apply.hh>
#include <egg/apply.hh>

namespace apple {

static int apply(int x) {
    return banana::apply(x) + egg::apply(x);
}

} // namespace apple

int main() {
    int const answer = apple::apply(5);
    std::cout << "The answer is " << answer << ".\n";
}
