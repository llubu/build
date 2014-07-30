#ifndef __TESTD_H__
#define __TESTD_H__

#ifdef TESTD_EXPORTS
	#ifdef _MSC_VER
		#define TESTD_API	__declspec(dllexport)
	#else /* Linux */
		#define TESTD_API	__attribute__ ((visibility ("default")))
	#endif /* _MSC_VER */
#else
	#ifdef _MSC_VER
		#define TESTD_API	__declspec(dllimport)
	#else /* Linux */
		#define TESTD_API
	#endif /* _MSC_VER */
#endif /* TESTC_EXPORTS */

void TESTD_API PrintNestedDependency(void);

#endif /* __TESTD_H__ */

