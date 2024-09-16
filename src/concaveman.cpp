#if 0
g++ -std=c++11 -shared concaveman.cpp -o libconcaveman.so
exit 0
#endif

//
// Author: Stanislaw Adaszewski, 2019
//


#include <erl_nif.h>
#include <vector>
#include <array>
#include <cstdlib>
#include "concaveman.h"

// C-compatible struct for points
typedef struct {
    double x;
    double y;
} Point;

// C-compatible wrapper function
extern "C" {
    Point* concaveman_wrapper(
        const Point* points,
        size_t points_count,
        const int* hull,
        size_t hull_count,
        double concavity,
        double lengthThreshold,
        size_t* result_count
    ) {
        typedef double T;
        typedef std::array<T, 2> point_type;

        // Convert C array to C++ vector
        std::vector<std::array<double, 2>> cpp_points(points_count);
        for (size_t i = 0; i < points_count; ++i) {
            cpp_points[i] = {points[i].x, points[i].y};
        }

        std::vector<int> cpp_hull(hull, hull + hull_count);

        

        // Call the C++ function
        auto result = concaveman<T, 16>(cpp_points, cpp_hull, concavity, lengthThreshold);
        // auto concave_points = concaveman<T, 16>(points, hull, concavity, lengthThreshold);

        // Convert the result back to C array
        *result_count = result.size();
        Point* c_result = (Point*)malloc(sizeof(Point) * *result_count);
        for (size_t i = 0; i < *result_count; ++i) {
            c_result[i].x = result[i][0];
            c_result[i].y = result[i][1];
        }

        return c_result;
    }
}

// Helper function to convert Erlang term to C array of points
static bool get_points(ErlNifEnv* env, ERL_NIF_TERM list, std::vector<Point>& points) {
    unsigned int length;
    if (!enif_get_list_length(env, list, &length)) return false;
    
    points.resize(length);
    ERL_NIF_TERM head, tail = list;
    
    for (unsigned int i = 0; i < length; i++) {
        if (!enif_get_list_cell(env, tail, &head, &tail)) return false;
        
        const ERL_NIF_TERM* tuple;
        int arity;
        if (!enif_get_tuple(env, head, &arity, &tuple) || arity != 2) return false;
        
        if (!enif_get_double(env, tuple[0], &points[i].x)) return false;
        if (!enif_get_double(env, tuple[1], &points[i].y)) return false;
    }
    
    return true;
}

// Helper function to convert Erlang term to C array of integers
static bool get_hull(ErlNifEnv* env, ERL_NIF_TERM list, std::vector<int>& hull) {
    unsigned int length;
    if (!enif_get_list_length(env, list, &length)) return false;
    
    hull.resize(length);
    ERL_NIF_TERM head, tail = list;
    
    for (unsigned int i = 0; i < length; i++) {
        if (!enif_get_list_cell(env, tail, &head, &tail)) return false;
        
        if (!enif_get_int(env, head, &hull[i])) return false;
    }
    
    return true;
}

// NIF function
static ERL_NIF_TERM concaveman(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 4) return enif_make_badarg(env);

    std::vector<Point> points;
    std::vector<int> hull;
    double concavity, lengthThreshold;

    if (!get_points(env, argv[0], points)) return enif_make_badarg(env);
    if (!get_hull(env, argv[1], hull)) return enif_make_badarg(env);
    if (!enif_get_double(env, argv[2], &concavity)) return enif_make_badarg(env);
    if (!enif_get_double(env, argv[3], &lengthThreshold)) return enif_make_badarg(env);

    size_t result_count;
    Point* result = concaveman_wrapper(points.data(), points.size(), 
                                       hull.data(), hull.size(), 
                                       concavity, lengthThreshold, &result_count);

    ERL_NIF_TERM result_list = enif_make_list(env, 0);
    for (size_t i = 0; i < result_count; ++i) {
        ERL_NIF_TERM point = enif_make_tuple2(env, 
            enif_make_double(env, result[result_count - 1 - i].x), 
            enif_make_double(env, result[result_count - 1 - i].y));
        result_list = enif_make_list_cell(env, point, result_list);
    }

    free(result);  // Don't forget to free the allocated memory

    return result_list;
}

    // double *points_c, 
    // size_t num_points,
    // int *hull_points_c, 
    // size_t num_hull_points,
    // double concavity, 
    // double lengthThreshold,
    // double **concave_points_c, 
    // size_t *num_concave_points,
    // void(**p_free)(void*));

    // std::cout << "pyconcaveman2d(), concavity: " << concavity <<
    //     " lengthThreshold: " << lengthThreshold << std::endl;

    // typedef double T;
    // typedef std::array<T, 2> point_type;

    // std::vector<point_type> points(num_points);
    // for (auto i = 0; i < num_points; i++) {
    //     points[i] = { points_c[i << 1], points_c[(i << 1) + 1] };
    // }

    // std::cout << "points:" << std::endl;
    // for (auto &p : points)
    //     std::cout << p[0] << " " << p[1] << std::endl;

    // std::vector<int> hull(num_hull_points);
    // for (auto i = 0; i < num_hull_points; i++) {
    //     hull[i] = hull_points_c[i];
    // }

    // std::cout << "hull:" << std::endl;
    // for (auto &i : hull)
    //     std::cout << i << std::endl;

    // auto concave_points = concaveman<T, 16>(points, hull, concavity, lengthThreshold);

    // for (auto &p : concave_points)
    //   std::cout << p[0] << " " << p[1] << std::endl;

    // double *concave_points_c = *p_concave_points_c = (double*) malloc(sizeof(double) * 2 * concave_points.size());
    // for (auto i = 0; i < concave_points.size(); i++) {
    //     concave_points_c[i << 1] = concave_points[i][0];
    //     concave_points_c[(i << 1) + 1] = concave_points[i][1];
    // }

    // *p_num_concave_points = concave_points.size();
    // *p_free = free;

    // std::cout << "concave_points:" << std::endl;

    // return enif_raise_exception(env, enif_make_atom(env, "not_implemented"));
// }


static ErlNifFunc nif_funcs[] = {
    {"concaveman", 4, concaveman, ERL_NIF_DIRTY_JOB_CPU_BOUND}
};

ERL_NIF_INIT(Elixir.Concaveman.Native, nif_funcs, NULL, NULL, NULL, NULL)


// extern "C" {
//     void pyconcaveman2d(double *points_c, size_t num_points,
//         int *hull_points_c, size_t num_hull_points,
//         double concavity, double lengthThreshold,
//         double **concave_points_c, size_t *num_concave_points,
//         void(**p_free)(void*));
// }

// void pyconcaveman2d(double *points_c, size_t num_points,
//     int *hull_points_c, size_t num_hull_points,
//     double concavity, double lengthThreshold,
//     double **p_concave_points_c,
//     size_t *p_num_concave_points,
//     void(**p_free)(void*)) {

//     std::cout << "pyconcaveman2d(), concavity: " << concavity <<
//         " lengthThreshold: " << lengthThreshold << std::endl;

//     typedef double T;
//     typedef std::array<T, 2> point_type;

//     std::vector<point_type> points(num_points);
//     for (auto i = 0; i < num_points; i++) {
//         points[i] = { points_c[i << 1], points_c[(i << 1) + 1] };
//     }

//     std::cout << "points:" << std::endl;
//     for (auto &p : points)
//         std::cout << p[0] << " " << p[1] << std::endl;

//     std::vector<int> hull(num_hull_points);
//     for (auto i = 0; i < num_hull_points; i++) {
//         hull[i] = hull_points_c[i];
//     }

//     std::cout << "hull:" << std::endl;
//     for (auto &i : hull)
//         std::cout << i << std::endl;

//     auto concave_points = concaveman<T, 16>(points, hull, concavity, lengthThreshold);

//     std::cout << "concave_points:" << std::endl;
//     for (auto &p : concave_points)
//         std::cout << p[0] << " " << p[1] << std::endl;

//     double *concave_points_c = *p_concave_points_c = (double*) malloc(sizeof(double) * 2 * concave_points.size());
//     for (auto i = 0; i < concave_points.size(); i++) {
//         concave_points_c[i << 1] = concave_points[i][0];
//         concave_points_c[(i << 1) + 1] = concave_points[i][1];
//     }

//     *p_num_concave_points = concave_points.size();
//     *p_free = free;
// }
