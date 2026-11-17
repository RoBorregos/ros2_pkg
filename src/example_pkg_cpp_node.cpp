#include <chrono>
#include <memory>

#include "rclcpp/rclcpp.hpp"

using namespace std::chrono_literals;

class ExampleCppNode : public rclcpp::Node
{
public:
  ExampleCppNode()
  : Node("example_cpp_node"), count_(0)
  {
    timer_ = this->create_wall_timer(
      500ms, [this]() {
        RCLCPP_INFO(this->get_logger(), "Hello from C++: %zu", count_++);
      });
  }

private:
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ExampleCppNode>());
  rclcpp::shutdown();
  return 0;
}
