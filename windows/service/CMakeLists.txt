# Служба собирается отдельным exe: она работает под LocalSystem и не должна
# тащить в свой процесс ни Flutter, ни плагины.
add_executable(verge_service
  "verge_service.cpp"
  "tunnel_worker.cpp"
  "${CMAKE_SOURCE_DIR}/runner/child_process.cpp"
)
apply_standard_settings(verge_service)
target_compile_definitions(verge_service PRIVATE "NOMINMAX" "UNICODE" "_UNICODE")
target_include_directories(verge_service PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_SOURCE_DIR}/runner")
target_link_libraries(verge_service PRIVATE "advapi32.lib")
set_target_properties(verge_service PROPERTIES OUTPUT_NAME "verge_service")

# install() для этой цели живёт в родительском windows/CMakeLists.txt: здесь
# CMAKE_INSTALL_PREFIX ещё не задан — его выставляют ниже по файлу, уже после
# add_subdirectory(service), — и служба уехала бы в дефолтный Program Files
# вместо каталога сборки.
